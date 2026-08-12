"""Create group 'مجموعة يحيي', link Yahya, set mapping.groupId."""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

# Reuse Firebase helpers from the sidecar server module.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from server import CONFIG_PATH, FirebaseClient, load_config  # noqa: E402


def main() -> None:
    cfg = load_config()
    fb = FirebaseClient(cfg)
    now = datetime.now(timezone.utc)

    students = fb.list_docs("students")
    yahya = next(
        (
            s
            for s in students
            if "يحي" in str(s.get("name", ""))
            or "yahya" in str(s.get("name", "")).lower()
        ),
        None,
    )
    if not yahya:
        raise SystemExit(f"Yahya student not found. Students: {[s.get('name') for s in students]}")

    grades = fb.list_docs("grades")
    subjects = fb.list_docs("subjects")
    teachers = fb.list_docs("teachers")
    if not grades or not subjects:
        raise SystemExit("Need at least one grade and one subject in Firestore.")

    grade_id = yahya.get("gradeId") or grades[0]["id"]
    # Prefer matching grade; fall back to first.
    if not any(g["id"] == grade_id for g in grades):
        grade_id = grades[0]["id"]
    subject_id = subjects[0]["id"]
    teacher_id = teachers[0]["id"] if teachers else None

    group_id = "group_yahya"
    group_data = {
        "name": "مجموعة يحيي",
        "branchId": fb.branch_id,
        "gradeId": grade_id,
        "subjectId": subject_id,
        "teacherId": teacher_id,
        "classroomId": None,
        "capacity": 20,
        "studentIds": [yahya["id"]],
        "createdAt": now,
        "updatedAt": now,
    }
    fb.upsert("groups", group_id, group_data)

    # Ensure Yahya's grade matches the group (teacher app links via gradeId).
    if yahya.get("gradeId") != grade_id:
        fb.upsert(
            "students",
            yahya["id"],
            {
                **{k: v for k, v in yahya.items() if k != "id"},
                "gradeId": grade_id,
                "updatedAt": now,
            },
        )

    # Enrollment in the group's grade (admin enrollments model).
    enrollments = fb.list_docs("enrollments")
    existing_enroll = next(
        (
            e
            for e in enrollments
            if e.get("studentId") == yahya["id"] and e.get("gradeId") == grade_id
        ),
        None,
    )
    if not existing_enroll:
        fb.upsert(
            "enrollments",
            f"enroll_{yahya['id']}_{grade_id}",
            {
                "studentId": yahya["id"],
                "gradeId": grade_id,
                "type": "full",
                "branchId": fb.branch_id,
                "fee": 0,
                "note": "مجموعة يحيي",
                "status": "active",
                "createdAt": now,
                "updatedAt": now,
            },
        )

    # Schedule today using current local hour as session window (optional helper).
    local = datetime.now().astimezone()
    weekday = local.isoweekday()  # 1=Mon ... 7=Sun
    start = local.replace(minute=0, second=0, microsecond=0)
    end_h = (start.hour + 2) % 24
    fb.upsert(
        "schedules",
        f"sched_{group_id}_{weekday}",
        {
            "groupId": group_id,
            "weekday": weekday,
            "startTime": start.strftime("%H:00"),
            "endTime": f"{end_h:02d}:00",
            "branchId": fb.branch_id,
            "createdAt": now,
            "updatedAt": now,
        },
    )

    # Attach groupId on biometric mapping(s) for Yahya.
    mappings = [
        m
        for m in fb.list_docs("biometric_mappings")
        if m.get("studentId") == yahya["id"] and not m.get("deletedAt")
    ]
    for m in mappings:
        fb.upsert(
            "biometric_mappings",
            m["id"],
            {
                **{k: v for k, v in m.items() if k != "id"},
                "groupId": group_id,
                "updatedAt": now,
            },
        )

    # Align late grace in config (already expected 5).
    cfg["late_after_minutes"] = 5
    CONFIG_PATH.write_text(
        json.dumps(cfg, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(
        json.dumps(
            {
                "ok": True,
                "group_id": group_id,
                "group_name": "مجموعة يحيي",
                "student_id": yahya["id"],
                "student_name": yahya.get("name"),
                "grade_id": grade_id,
                "subject_id": subject_id,
                "teacher_id": teacher_id,
                "mappings_updated": [m["id"] for m in mappings],
                "late_after_minutes": 5,
                "schedule": {
                    "weekday": weekday,
                    "startTime": start.strftime("%H:00"),
                    "endTime": f"{end_h:02d}:00",
                },
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
