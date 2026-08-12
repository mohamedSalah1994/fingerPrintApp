import json
from pathlib import Path

import httpx

cfg = json.loads(
    Path(r"d:/projects/fingerPrintApp/zk_sidecar/config.json").read_text(
        encoding="utf-8"
    )
)
auth = httpx.post(
    f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
    f"?key={cfg['firebase_web_api_key']}",
    json={
        "email": cfg["admin_email"],
        "password": cfg["admin_password"],
        "returnSecureToken": True,
    },
    timeout=30,
).json()
h = {"Authorization": f"Bearer {auth['idToken']}"}
base = (
    f"https://firestore.googleapis.com/v1/projects/{cfg['firebase_project_id']}"
    "/databases/(default)/documents"
)


def parse(v):
    if "stringValue" in v:
        return v["stringValue"]
    if "integerValue" in v:
        return int(v["integerValue"])
    return v


def docs(col):
    r = httpx.get(f"{base}/{col}?pageSize=100", headers=h, timeout=60)
    out = []
    for d in r.json().get("documents", []):
        p = {"id": d["name"].split("/")[-1]}
        for k, v in d.get("fields", {}).items():
            p[k] = parse(v)
        if p.get("deletedAt"):
            continue
        out.append(p)
    return out


stages = {s["id"]: s.get("name") for s in docs("stages")}
grades = {g["id"]: g for g in docs("grades")}
print("STAGES:", stages)
print("GRADES:")
for g in grades.values():
    print(
        " ",
        g.get("name"),
        "->",
        stages.get(g.get("stageId"), g.get("stageId")),
    )
print("SUBJECTS:")
for s in docs("subjects"):
    gid = s.get("gradeId")
    g = grades.get(gid or "")
    print(
        " ",
        s.get("name"),
        "| storedStage=",
        stages.get(s.get("stageId"), s.get("stageId")),
        "| grade=",
        (g or {}).get("name"),
        "| grade.stage=",
        stages.get((g or {}).get("stageId"), (g or {}).get("stageId")),
    )
