"""
ZKTeco K50 Pro sidecar — polls attendance via pyzk and writes to Firestore.

Run:
  pip install -r requirements.txt
  copy config.example.json config.json   # edit admin password / defaults
  python server.py

API (default http://127.0.0.1:8765):
  GET  /health
  POST /test-connection   {ip, port, comm_key, force_udp}
  GET  /device-users?device_id=...
  POST /sync              {device_id?}  sync one or all active devices
  POST /sync-loop/start
  POST /sync-loop/stop
"""

from __future__ import annotations

import json
import logging
import socket
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from zk import ZK

ROOT = Path(__file__).resolve().parent
CONFIG_PATH = ROOT / "config.json"
LOG = logging.getLogger("zk_sidecar")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")


class PrivateNetworkAccessMiddleware(BaseHTTPMiddleware):
    """Allow HTTPS hosted admin (Firebase) to call this local helper from Chrome/Edge."""

    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)
        response.headers["Access-Control-Allow-Private-Network"] = "true"
        return response


app = FastAPI(title="MECMS ZKTeco Sidecar", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Outermost: attach PNA header even on CORS preflight responses.
app.add_middleware(PrivateNetworkAccessMiddleware)

_loop_thread: threading.Thread | None = None
_loop_stop = threading.Event()
_id_token: str | None = None
_id_token_exp = 0.0


def load_config() -> dict[str, Any]:
    if not CONFIG_PATH.exists():
        example = ROOT / "config.example.json"
        raise FileNotFoundError(
            f"Missing {CONFIG_PATH}. Copy {example.name} to config.json and edit it."
        )
    with CONFIG_PATH.open(encoding="utf-8") as f:
        return json.load(f)


def _firestore_fields(obj: dict[str, Any]) -> dict[str, Any]:
    fields: dict[str, Any] = {}
    for k, v in obj.items():
        if v is None:
            continue
        if isinstance(v, bool):
            fields[k] = {"booleanValue": v}
        elif isinstance(v, int) and not isinstance(v, bool):
            fields[k] = {"integerValue": str(v)}
        elif isinstance(v, float):
            fields[k] = {"doubleValue": v}
        elif isinstance(v, datetime):
            fields[k] = {"timestampValue": v.astimezone().isoformat()}
        elif isinstance(v, list):
            fields[k] = {
                "arrayValue": {
                    "values": [
                        {"stringValue": str(x)}
                        if not isinstance(x, dict)
                        else {"mapValue": {"fields": _firestore_fields(x)}}
                        for x in v
                    ]
                }
            }
        else:
            fields[k] = {"stringValue": str(v)}
    return fields


def _parse_firestore_value(v: dict[str, Any]) -> Any:
    if "stringValue" in v:
        return v["stringValue"]
    if "integerValue" in v:
        return int(v["integerValue"])
    if "booleanValue" in v:
        return v["booleanValue"]
    if "timestampValue" in v:
        return v["timestampValue"]
    if "doubleValue" in v:
        return float(v["doubleValue"])
    if "nullValue" in v:
        return None
    if "arrayValue" in v:
        return [
            _parse_firestore_value(x)
            for x in (v["arrayValue"].get("values") or [])
        ]
    if "mapValue" in v:
        fields = v["mapValue"].get("fields") or {}
        return {k: _parse_firestore_value(fv) for k, fv in fields.items()}
    return None


class FirebaseClient:
    def __init__(self, cfg: dict[str, Any]):
        self.cfg = cfg
        self.api_key = cfg["firebase_web_api_key"]
        self.project = cfg["firebase_project_id"]
        self.branch_id = cfg.get("branch_id", "default_branch")

    def id_token(self) -> str:
        global _id_token, _id_token_exp
        now = time.time()
        if _id_token and now < _id_token_exp - 60:
            return _id_token
        url = (
            "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
            f"?key={self.api_key}"
        )
        with httpx.Client(timeout=30) as client:
            res = client.post(
                url,
                json={
                    "email": self.cfg["admin_email"],
                    "password": self.cfg["admin_password"],
                    "returnSecureToken": True,
                },
            )
            data = res.json()
            if "idToken" not in data:
                raise RuntimeError(f"Firebase auth failed: {data}")
            _id_token = data["idToken"]
            _id_token_exp = now + int(data.get("expiresIn", "3600"))
            return _id_token

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.id_token()}",
            "Content-Type": "application/json",
        }

    def list_docs(self, collection: str) -> list[dict[str, Any]]:
        url = (
            f"https://firestore.googleapis.com/v1/projects/{self.project}"
            f"/databases/(default)/documents/{collection}?pageSize=300"
        )
        with httpx.Client(timeout=60) as client:
            res = client.get(url, headers=self._headers())
            res.raise_for_status()
            docs = res.json().get("documents", [])
        out = []
        for doc in docs:
            fields = doc.get("fields", {})
            parsed = {"id": doc["name"].split("/")[-1]}
            for k, v in fields.items():
                parsed[k] = _parse_firestore_value(v)
            if parsed.get("placeholder") is True or parsed.get("deletedAt"):
                continue
            out.append(parsed)
        return out

    def upsert(self, collection: str, doc_id: str, data: dict[str, Any]) -> None:
        url = (
            f"https://firestore.googleapis.com/v1/projects/{self.project}"
            f"/databases/(default)/documents/{collection}/{doc_id}"
        )
        payload = {"fields": _firestore_fields(data)}
        with httpx.Client(timeout=60) as client:
            res = client.patch(url, headers=self._headers(), json=payload)
            if res.status_code >= 300:
                # Some creates need POST with documentId=
                create_url = (
                    f"https://firestore.googleapis.com/v1/projects/{self.project}"
                    f"/databases/(default)/documents/{collection}?documentId={doc_id}"
                )
                res2 = client.post(create_url, headers=self._headers(), json=payload)
                if res2.status_code >= 300:
                    raise RuntimeError(
                        f"Firestore upsert failed {collection}/{doc_id}: "
                        f"patch={res.text} post={res2.text}"
                    )


def _preflight_reachable(ip: str, port: int, timeout: float = 2.0) -> None:
    """Fail fast when the device IP is not reachable on the LAN."""
    try:
        with socket.create_connection((ip, int(port)), timeout=timeout):
            return
    except OSError as e:
        raise RuntimeError(
            f"Device unreachable at {ip}:{port} — check cable/Wi-Fi/same network. ({e})"
        ) from e


def connect_zk(
    ip: str,
    port: int,
    comm_key: int,
    force_udp: bool,
    timeout: int = 5,
):
    """Connect to device; try preferred mode then the other (TCP/UDP)."""
    last_err: Exception | None = None
    modes = [True, False] if force_udp else [False, True]
    for use_udp in modes:
        try:
            if not use_udp:
                _preflight_reachable(ip, port, timeout=min(2.0, float(timeout)))
            zk = ZK(
                ip,
                port=port,
                timeout=timeout,
                password=int(comm_key or 0),
                force_udp=bool(use_udp),
                ommit_ping=True,
            )
            return zk.connect()
        except Exception as e:
            last_err = e
            LOG.warning("ZK connect failed ip=%s udp=%s: %s", ip, use_udp, e)
            msg = str(e).lower()
            if (
                "unreachable" in msg
                or "no route" in msg
                or "network is unreachable" in msg
                or "forcibly closed" in msg
            ):
                break
    assert last_err is not None
    raise RuntimeError(
        f"Cannot connect to ZKTeco {ip}:{port}. "
        f"Check power/cable/same Wi-Fi (ping {ip}). Last error: {last_err}"
    ) from last_err


# Serialize device IO so auto-sync and UI actions don't overlap.
_zk_lock = threading.Lock()

def _parse_hhmm(value: str | None, fallback: tuple[int, int] = (16, 0)) -> tuple[int, int]:
    try:
        hh, mm = [int(x) for x in str(value or "").split(":")[:2]]
        return hh, mm
    except Exception:
        return fallback


def normalize_punch_timestamp(ts: datetime, cfg: dict[str, Any]) -> tuple[datetime, bool]:
    """
    ZK devices often have wrong date/year. If the punch calendar day is skewed
    vs the PC clock beyond the configured threshold, keep the punch clock time
    but rebase onto the PC's current date so sessions match Mon/Wed/Sat etc.
    """
    now = datetime.now()
    local_ts = ts if ts.tzinfo is None else ts.astimezone().replace(tzinfo=None)
    skew_days = abs((local_ts.date() - now.date()).days)
    max_skew = int(cfg.get("max_device_clock_skew_days", 1))
    if skew_days <= max_skew:
        return local_ts, False
    fixed = now.replace(
        hour=local_ts.hour,
        minute=local_ts.minute,
        second=local_ts.second,
        microsecond=0,
    )
    LOG.warning(
        "Device clock skew %s days — rebasing punch %s → %s",
        skew_days,
        local_ts.isoformat(sep=" ", timespec="seconds"),
        fixed.isoformat(sep=" ", timespec="seconds"),
    )
    return fixed, True


def _group_active_on(group: dict[str, Any], date_key: str) -> bool:
    start = group.get("startDate")
    end = group.get("endDate")
    if start and str(date_key) < str(start):
        return False
    if end and str(date_key) > str(end):
        return False
    return True


def _schedules_from_groups(groups: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for g in groups:
        if g.get("deletedAt"):
            continue
        for s in g.get("sessions") or []:
            weekdays = s.get("weekdays")
            if not weekdays:
                wd = s.get("weekday")
                weekdays = [wd] if wd is not None else []
            for wd in weekdays:
                out.append(
                    {
                        "groupId": g["id"],
                        "weekday": wd,
                        "startTime": s.get("startTime"),
                        "endTime": s.get("endTime"),
                        "subjectId": s.get("subjectId"),
                    }
                )
    return out


def _effective_schedules(
    fb: "FirebaseClient",
    groups: list[dict[str, Any]] | None = None,
) -> list[dict[str, Any]]:
    schedules = [s for s in fb.list_docs("schedules") if not s.get("deletedAt")]
    if schedules:
        return schedules
    gs = groups if groups is not None else [
        g for g in fb.list_docs("groups") if not g.get("deletedAt")
    ]
    return _schedules_from_groups(gs)


def session_start_for_punch(
    ts: datetime,
    group_id: str | None,
    schedules: list[dict[str, Any]],
    cfg: dict[str, Any],
) -> str:
    """Prefer Firestore weekly schedule for the group; else config default."""
    weekday = ts.isoweekday()  # 1=Mon ... 7=Sun (matches admin UI)
    if group_id:
        matches = [
            s
            for s in schedules
            if s.get("groupId") == group_id
            and int(s.get("weekday", 0) or 0) == weekday
            and not s.get("deletedAt")
        ]
        if matches:
            # If multiple slots same day, pick the one whose start is closest before punch,
            # else the earliest start.
            def start_minutes(s: dict[str, Any]) -> int:
                hh, mm = _parse_hhmm(s.get("startTime"))
                return hh * 60 + mm

            punch_m = ts.hour * 60 + ts.minute
            before = [s for s in matches if start_minutes(s) <= punch_m]
            chosen = max(before, key=start_minutes) if before else min(matches, key=start_minutes)
            return str(chosen.get("startTime") or cfg.get("default_session_start", "16:00"))
    return str(cfg.get("default_session_start", "16:00"))


def status_for_punch(
    ts: datetime,
    cfg: dict[str, Any],
    *,
    group_id: str | None = None,
    schedules: list[dict[str, Any]] | None = None,
) -> str:
    """Mark late if after session start + grace minutes (schedule-aware)."""
    start = session_start_for_punch(ts, group_id, schedules or [], cfg)
    grace = int(cfg.get("late_after_minutes", 15))
    hh, mm = _parse_hhmm(start)
    threshold = ts.replace(hour=hh, minute=mm, second=0, microsecond=0) + timedelta(
        minutes=grace
    )
    return "late" if ts > threshold else "present"


class TestConnectionBody(BaseModel):
    ip: str
    port: int = 4370
    comm_key: int = 0
    force_udp: bool = False


class SyncBody(BaseModel):
    device_id: str | None = None
    clear_after_sync: bool = False


@app.get("/health")
def health():
    cfg_ok = CONFIG_PATH.exists()
    return {
        "ok": True,
        "config": cfg_ok,
        "loop_running": _loop_thread is not None and _loop_thread.is_alive(),
    }


@app.post("/test-connection")
def test_connection(body: TestConnectionBody):
    conn = None
    with _zk_lock:
        try:
            conn = connect_zk(body.ip, body.port, body.comm_key, body.force_udp)
            conn.disable_device()
            name = conn.get_device_name()
            users = conn.get_users() or []
            firmware = None
            try:
                firmware = conn.get_firmware_version()
            except Exception:
                pass
            return {
                "ok": True,
                "device_name": name,
                "firmware": firmware,
                "users_count": len(users),
                "users": [
                    {
                        "uid": u.uid,
                        "user_id": str(u.user_id),
                        "name": u.name,
                    }
                    for u in users[:50]
                ],
            }
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e)) from e
        finally:
            if conn:
                try:
                    conn.enable_device()
                except Exception:
                    pass
                try:
                    conn.disconnect()
                except Exception:
                    pass


@app.get("/device-users")
def device_users(device_id: str):
    cfg = load_config()
    fb = FirebaseClient(cfg)
    devices = [d for d in fb.list_docs("devices") if d["id"] == device_id]
    if not devices:
        raise HTTPException(404, "Device not found in Firestore")
    d = devices[0]
    ip = d.get("ipAddress")
    if not ip:
        raise HTTPException(400, "Device has no ipAddress")
    conn = None
    with _zk_lock:
        try:
            conn = connect_zk(
                ip,
                int(d.get("port", 4370)),
                int(d.get("commKey", 0)),
                bool(d.get("forceUdp", False)),
            )
            conn.disable_device()
            users = conn.get_users() or []
            return {
                "ok": True,
                "users": [
                    {"uid": u.uid, "user_id": str(u.user_id), "name": u.name}
                    for u in users
                ],
            }
        except Exception as e:
            raise HTTPException(400, detail=str(e)) from e
        finally:
            if conn:
                try:
                    conn.enable_device()
                except Exception:
                    pass
                try:
                    conn.disconnect()
                except Exception:
                    pass


def sync_device(fb: FirebaseClient, device: dict[str, Any], cfg: dict[str, Any], clear: bool = False) -> dict[str, Any]:
    ip = device.get("ipAddress")
    if not ip:
        return {"device_id": device["id"], "ok": False, "error": "missing ipAddress"}

    mappings = [
        m
        for m in fb.list_docs("biometric_mappings")
        if m.get("deviceId") == device["id"] and m.get("status", "active") == "active"
    ]
    by_device_user = {str(m.get("deviceUserId")): m for m in mappings}
    groups = [g for g in fb.list_docs("groups") if not g.get("deletedAt")]
    schedules = _effective_schedules(fb, groups)
    students_by_id = {s["id"]: s for s in fb.list_docs("students")}

    def resolve_group_id(mapping: dict[str, Any], punch_ts: datetime) -> str | None:
        student = students_by_id.get(mapping.get("studentId", ""))
        if not student:
            return None
        sid = student["id"]
        # Prefer groups that explicitly list this student.
        listed = [
            g
            for g in groups
            if sid in (g.get("studentIds") or [])
        ]
        mapped_gid = mapping.get("groupId")
        if mapped_gid and any(g["id"] == mapped_gid for g in listed):
            return str(mapped_gid)
        if len(listed) == 1:
            return listed[0]["id"]
        if len(listed) > 1:
            weekday = punch_ts.isoweekday()
            punch_m = punch_ts.hour * 60 + punch_ts.minute
            best: tuple[int, str] | None = None
            for g in listed:
                if not _group_active_on(g, punch_ts.strftime("%Y-%m-%d")):
                    continue
                for s in schedules:
                    if s.get("groupId") != g["id"]:
                        continue
                    if int(s.get("weekday", 0) or 0) != weekday:
                        continue
                    start_m = _minutes_of(s.get("startTime"))
                    end_m = _minutes_of(s.get("endTime"), (23, 59))
                    # Allow punch from 60 min before start until 90 min after end.
                    if start_m - 60 <= punch_m <= end_m + 90:
                        dist = abs(punch_m - start_m)
                        if best is None or dist < best[0]:
                            best = (dist, g["id"])
            if best:
                return best[1]
            return listed[0]["id"]
        # Not enrolled in any group — do not invent membership via grade.
        return None

    conn = None
    created = 0
    skipped = 0
    unmapped = 0
    clock_fixed = 0
    if not _zk_lock.acquire(timeout=25):
        return {
            "device_id": device["id"],
            "ok": False,
            "error": "Device busy — another operation in progress",
        }
    try:
        conn = connect_zk(
            ip,
            int(device.get("port", 4370)),
            int(device.get("commKey", 0)),
            bool(device.get("forceUdp", False)),
            timeout=8,
        )
        conn.disable_device()
        punches = conn.get_attendance() or []
        # Also index mappings by numeric-normalized ids ("1003" / "01003")
        by_device_user_norm = {
            str(k).lstrip("0") or "0": v for k, v in by_device_user.items()
        }
        sample_punch_ids: list[str] = []
        unmapped_ids: list[str] = []
        for p in punches:
            raw_user = getattr(p, "user_id", None)
            raw_uid = getattr(p, "uid", None)
            user_id = str(raw_user if raw_user is not None else "")
            uid_id = str(raw_uid if raw_uid is not None else "")
            raw_ts = getattr(p, "timestamp", None)
            if not isinstance(raw_ts, datetime):
                skipped += 1
                continue
            ts, was_fixed = normalize_punch_timestamp(raw_ts, cfg)
            if was_fixed:
                clock_fixed += 1
            if len(sample_punch_ids) < 10:
                sample_punch_ids.append(
                    f"user_id={user_id}|uid={uid_id}|ts={ts}"
                    + (f"|raw={raw_ts}" if was_fixed else "")
                )

            mapping = (
                by_device_user.get(user_id)
                or by_device_user.get(uid_id)
                or by_device_user_norm.get(user_id.lstrip("0") or "0")
                or by_device_user_norm.get(uid_id.lstrip("0") or "0")
            )
            if not mapping:
                unmapped += 1
                key = user_id or uid_id or "?"
                if key not in unmapped_ids and len(unmapped_ids) < 20:
                    unmapped_ids.append(key)
                continue

            student_id = mapping["studentId"]
            group_id = resolve_group_id(mapping, ts)
            date_key = ts.strftime("%Y-%m-%d")
            # Prefer badge/user_id for stable ids; fall back to uid.
            stable_user = user_id or uid_id or "unknown"
            punch_unix = int(ts.timestamp())
            doc_id = f"zk_{device['id']}_{stable_user}_{punch_unix}"
            status = status_for_punch(
                ts, cfg, group_id=group_id, schedules=schedules
            )
            note = "ZKTeco auto sync"
            if was_fixed:
                note = f"{note} (device clock corrected)"
            fb.upsert(
                "attendances",
                doc_id,
                {
                    "studentId": student_id,
                    "branchId": fb.branch_id,
                    "date": date_key,
                    "status": status,
                    "source": "fingerprint",
                    "groupId": group_id,
                    "checkInAt": ts,
                    "deviceId": device["id"],
                    "deviceUserId": stable_user,
                    "note": note,
                    "recordedBy": "zk_sidecar",
                    "createdAt": datetime.utcnow(),
                    "updatedAt": datetime.utcnow(),
                },
            )
            created += 1
        if clear:
            try:
                conn.clear_attendance()
            except Exception as e:
                LOG.warning("clear_attendance failed: %s", e)
        fb.upsert(
            "devices",
            device["id"],
            {
                "name": device.get("name", "ZKTeco"),
                "branchId": device.get("branchId", fb.branch_id),
                "serialNumber": device.get("serialNumber", ""),
                "vendor": device.get("vendor", "zkteco"),
                "model": device.get("model", "K50 Pro"),
                "status": "active",
                "location": device.get("location"),
                "ipAddress": device.get("ipAddress"),
                "port": int(device.get("port", 4370)),
                "commKey": int(device.get("commKey", 0)),
                "forceUdp": bool(device.get("forceUdp", False)),
                "lastSyncAt": datetime.utcnow(),
                "updatedAt": datetime.utcnow(),
            },
        )
        return {
            "device_id": device["id"],
            "ok": True,
            "punches": len(punches),
            "written": created,
            "skipped": skipped,
            "unmapped": unmapped,
            "clock_fixed": clock_fixed,
            "mapped_keys": list(by_device_user.keys()),
            "unmapped_ids": unmapped_ids,
            "sample_punches": sample_punch_ids,
        }
    except Exception as e:
        LOG.exception("sync failed for %s", device.get("id"))
        return {"device_id": device.get("id"), "ok": False, "error": str(e)}
    finally:
        if conn:
            try:
                conn.enable_device()
            except Exception:
                pass
            try:
                conn.disconnect()
            except Exception:
                pass
        _zk_lock.release()


def _minutes_of(value: str | None, fallback: tuple[int, int] = (0, 0)) -> int:
    hh, mm = _parse_hhmm(value, fallback)
    return hh * 60 + mm


def _slots_consecutive(earlier: dict[str, Any], later: dict[str, Any]) -> bool:
    if int(earlier.get("weekday", -1) or -1) != int(later.get("weekday", -2) or -2):
        return False
    if str(earlier.get("groupId")) != str(later.get("groupId")):
        return False
    end = _minutes_of(earlier.get("endTime"), (23, 59))
    start = _minutes_of(later.get("startTime"))
    prev_start = _minutes_of(earlier.get("startTime"))
    return start >= end - 5 and start <= end + 30 and start >= prev_start


def _previous_consecutive_slot(
    slot: dict[str, Any], schedules: list[dict[str, Any]]
) -> dict[str, Any] | None:
    weekday = int(slot.get("weekday", 0) or 0)
    gid = str(slot.get("groupId") or "")
    start = _minutes_of(slot.get("startTime"))
    same = [
        s
        for s in schedules
        if str(s.get("groupId") or "") == gid
        and int(s.get("weekday", 0) or 0) == weekday
        and _minutes_of(s.get("startTime")) < start
    ]
    if not same:
        return None
    prev = max(same, key=lambda s: _minutes_of(s.get("startTime")))
    return prev if _slots_consecutive(prev, slot) else None


def _punch_in_slot_window(
    punch_m: int,
    slot: dict[str, Any],
    *,
    before: int = 45,
    after: int = 20,
) -> bool:
    start = _minutes_of(slot.get("startTime"))
    end = _minutes_of(slot.get("endTime"), (23, 59))
    return start - before <= punch_m <= end + after


def _session_end_dt(day: datetime, end_time: str) -> datetime:
    hh, mm = _parse_hhmm(end_time, (23, 59))
    return day.replace(hour=hh, minute=mm, second=0, microsecond=0)


def _students_for_group(
    group: dict[str, Any],
    students: list[dict[str, Any]],
    mappings: list[dict[str, Any]] | None = None,
) -> list[dict[str, Any]]:
    """Only students explicitly listed on the group — never the whole grade."""
    raw = group.get("studentIds") or []
    ids = {str(sid) for sid in raw if sid}
    # Ignore biometric mapping.groupId for roster — membership is studentIds only.
    return [s for s in students if s["id"] in ids and not s.get("deletedAt")]


def mark_absences(fb: FirebaseClient, cfg: dict[str, Any]) -> dict[str, Any]:
    """After a session ends, mark group students with no punch as absent."""
    now = datetime.now()
    date_key = now.strftime("%Y-%m-%d")
    weekday = now.isoweekday()
    groups_list = [g for g in fb.list_docs("groups") if not g.get("deletedAt")]
    groups = {g["id"]: g for g in groups_list}
    schedules = _effective_schedules(fb, groups_list)
    students = [s for s in fb.list_docs("students") if not s.get("deletedAt")]
    mappings = [
        m
        for m in fb.list_docs("biometric_mappings")
        if m.get("status", "active") == "active" and not m.get("deletedAt")
    ]
    attendances = [
        a
        for a in fb.list_docs("attendances")
        if a.get("date") == date_key and not a.get("deletedAt")
    ]

    def has_record(student_id: str, group_id: str, slot: dict[str, Any]) -> bool:
        punch_slots = [slot]
        prev = _previous_consecutive_slot(slot, schedules)
        if prev:
            punch_slots.append(prev)
        for a in attendances:
            if a.get("studentId") != student_id:
                continue
            ag = a.get("groupId")
            if ag not in (group_id, None, ""):
                continue
            # Any fingerprint/manual presence that day covers this slot,
            # and also covers the next back-to-back slot.
            status = str(a.get("status") or "")
            if status in ("present", "late", "excused"):
                check = a.get("checkInAt")
                if not check:
                    return True
                # Parse HH:MM from ISO-ish timestamp if possible.
                try:
                    if isinstance(check, str) and "T" in check:
                        tpart = check.split("T", 1)[1]
                        hh, mm = [int(x) for x in tpart.split(":")[:2]]
                        punch_m = hh * 60 + mm
                    else:
                        return True
                except Exception:
                    return True
                for s in punch_slots:
                    if _punch_in_slot_window(punch_m, s):
                        return True
                # No time match but same day group record — still counts
                # when only one slot that day.
                same_day = [
                    s
                    for s in schedules
                    if str(s.get("groupId") or "") == group_id
                    and int(s.get("weekday", 0) or 0) == weekday
                ]
                if len(same_day) <= 1:
                    return True
        return False

    written = 0
    skipped = 0
    considered = 0
    for slot in schedules:
        if int(slot.get("weekday", 0) or 0) != weekday:
            continue
        group_id = slot.get("groupId")
        group = groups.get(group_id or "")
        if not group or not group_id:
            continue
        if not _group_active_on(group, date_key):
            continue
        end_dt = _session_end_dt(now, str(slot.get("endTime") or "23:59"))
        if now < end_dt:
            continue  # session still running
        for student in _students_for_group(group, students):
            considered += 1
            sid = student["id"]
            if not sid:
                continue
            if has_record(sid, group_id, slot):
                skipped += 1
                continue
            # Skip creating absents for students no longer in the group roster
            # (defensive — roster already filtered).
            doc_id = f"absent_{group_id}_{sid}_{date_key}_{slot.get('startTime', '')}"
            payload = {
                "studentId": sid,
                "branchId": fb.branch_id,
                "date": date_key,
                "status": "absent",
                "source": "device",
                "groupId": group_id,
                "note": "Auto absent — no fingerprint before session end",
                "recordedBy": "zk_sidecar",
                "createdAt": datetime.utcnow(),
                "updatedAt": datetime.utcnow(),
            }
            fb.upsert("attendances", doc_id, payload)
            attendances.append({"id": doc_id, **payload})
            written += 1
    return {
        "ok": True,
        "date": date_key,
        "considered": considered,
        "written": written,
        "skipped": skipped,
    }


@app.post("/sync")
def sync(body: SyncBody = SyncBody()):
    cfg = load_config()
    fb = FirebaseClient(cfg)
    devices = [
        d
        for d in fb.list_docs("devices")
        if d.get("status", "active") != "deleted"
        and d.get("placeholder") is not True
    ]
    if body.device_id:
        devices = [d for d in devices if d["id"] == body.device_id]
        if not devices:
            raise HTTPException(404, "Device not found")
    results = [sync_device(fb, d, cfg, clear=body.clear_after_sync) for d in devices]
    absences = mark_absences(fb, cfg)
    return {
        "ok": all(r.get("ok") for r in results) if results else True,
        "results": results,
        "absences": absences,
    }


def _loop_worker():
    cfg = load_config()
    seconds = int(cfg.get("poll_seconds", 30))
    LOG.info("Auto-sync loop started (every %ss)", seconds)
    while not _loop_stop.is_set():
        try:
            fb = FirebaseClient(cfg)
            devices = [
                d
                for d in fb.list_docs("devices")
                if d.get("status") == "active" and d.get("ipAddress")
            ]
            for d in devices:
                result = sync_device(fb, d, cfg)
                LOG.info("sync %s", result)
            absences = mark_absences(fb, cfg)
            LOG.info("absences %s", absences)
        except Exception as e:
            LOG.exception("loop error: %s", e)
        _loop_stop.wait(seconds)
    LOG.info("Auto-sync loop stopped")


@app.post("/sync-loop/start")
def start_loop():
    global _loop_thread
    if _loop_thread and _loop_thread.is_alive():
        return {"ok": True, "message": "already running"}
    _loop_stop.clear()
    _loop_thread = threading.Thread(target=_loop_worker, daemon=True)
    _loop_thread.start()
    return {"ok": True, "message": "started"}


@app.post("/sync-loop/stop")
def stop_loop():
    _loop_stop.set()
    return {"ok": True, "message": "stopping"}


@app.on_event("startup")
def _on_startup():
    cfg = load_config()
    if cfg.get("auto_start_sync_loop", True):
        start_loop()
        LOG.info("Auto-sync loop enabled at startup (config auto_start_sync_loop)")


if __name__ == "__main__":
    import uvicorn

    cfg = load_config()
    host = cfg.get("sidecar_host", "127.0.0.1")
    port = int(cfg.get("sidecar_port", 8765))
    uvicorn.run("server:app", host=host, port=port, reload=False)
