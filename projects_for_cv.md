# Projects Included in Updated CV (Evidence Notes)

This file documents which projects were added/updated in `updated_cv.md` based on verifiable evidence inside `/workspace`.

## 1) MECMS Fingerprint Attendance & Center Management Platform

### Why included
- Main repository in `/workspace` is a Flutter project with app title `MECMS` and fingerprint-attendance domain logic.
- Git history shows collaborative development in this repo, including initial commit by **Cursor Agent** and later commits by **mohamedSalah1994**.

### Evidence
- Project identity:
  - `/workspace/README.md` (`# fingerPrintApp`)
  - `/workspace/lib/main.dart` (`title: 'MECMS'`)
- Feature scope and modules:
  - `/workspace/lib/app/router/app_router.dart` (admin routes: dashboard, students, teachers, groups, attendance, devices, users, settings, etc.)
  - `/workspace/lib/features/admin/presentation/pages/attendance_page.dart`
  - `/workspace/lib/features/admin/presentation/pages/dashboard_page.dart`
  - `/workspace/lib/features/admin/presentation/pages/devices_page.dart`
- Data model breadth:
  - `/workspace/lib/core/constants/firestore_paths.dart` (collections for students, groups, schedules, attendances, devices, biometric mappings, etc.)
- Git evidence:
  - `git log --oneline --decorate -n 25`
  - `git show --stat --oneline 9c94328` (large attendance/devices/dashboard expansion)

### Notes on certainty
- High confidence this is a core project built together in this workspace.
- Business KPIs (active users/revenue/adoption) are not present in repo; CV uses technical impact only.

---

## 2) ZKTeco K50 Pro Sidecar Sync Service (Local helper service)

### Why included
- Dedicated subproject under `/workspace/zk_sidecar` with standalone Python service, docs, config, and startup scripts.
- It directly integrates with the Flutter app’s devices/attendance workflows.

### Evidence
- Overview and setup:
  - `/workspace/zk_sidecar/README.md`
- Implementation:
  - `/workspace/zk_sidecar/server.py` (FastAPI app, sync loop, Firestore writes, absence marking, device connection handling)
  - `/workspace/zk_sidecar/config.example.json` (polling and attendance settings)
- Operational usage docs:
  - `/workspace/docs/ZKTECO_AR.md`
- App integration points:
  - `/workspace/lib/core/services/zk_sidecar_client.dart`
  - `/workspace/lib/features/admin/presentation/pages/devices_page.dart`

### Notes on certainty
- High confidence this is a meaningful project/component built in the same collaboration cycle.
- Endpoint count and polling interval are directly inferable from source.

---

## 3) Firebase Data Seeding & Environment Bootstrap Scripts

### Why included
- `tools` directory contains scripts and dependencies specifically for data bootstrapping and seeded test/demo scenarios.
- Scripts cover realistic education-domain entities and support app validation.

### Evidence
- Tooling package:
  - `/workspace/tools/package.json`
- Seeding logic:
  - `/workspace/tools/seed_teacher_data.js`
  - `/workspace/tools/seed_firestore.js`
  - `/workspace/tools/seed_with_access.js`
  - `/workspace/tools/seed_teacher_data.ps1`
  - `/workspace/tools/seed_attendance_data.ps1`

### Notes on certainty
- Medium-high confidence this is a project-grade internal tooling effort (not just a temporary script) due to breadth and structure.
- No explicit runtime metrics available in repo.

---

## Projects from original PDF CV that were retained but not re-validated from `/workspace`

These were kept in the revised CV to preserve the candidate’s existing portfolio, but they are sourced from the uploaded PDF content rather than repository artifacts in `/workspace`:
- ElMola
- House Made
- Her Station
- ID Scanner
- Barcode Scanner

If needed, these can be further validated by checking their referenced app store/GitHub links.
