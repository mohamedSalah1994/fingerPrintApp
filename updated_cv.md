## MOHAMED SALAH
**Flutter Developer**  
Cairo, Egypt  
(+20) 102 698 3635  
elkomymohamed69@gmail.com  
LinkedIn: https://www.linkedin.com/in/mohamed-elkomy30

---

## Professional Summary
Flutter developer with 5+ years of software development experience, including 4+ years focused on cross-platform mobile and web solutions using Flutter and Dart. Strong in clean architecture, Firebase integration, state management, and production-focused UI/UX implementation. Experienced in building education and operations platforms with attendance workflows, admin dashboards, and device/API integrations. Additional backend background in PHP/Laravel.

## Core Skills
- **Languages & Frameworks:** Dart, Flutter, PHP, Laravel, Python (integration services)
- **Architecture & Patterns:** Clean Architecture, BLoC, Provider, MVVM concepts
- **Backend & Cloud:** Firebase Auth, Cloud Firestore, Firebase Storage, Firebase Hosting, REST APIs
- **App Features:** Authentication, role-based access, attendance workflows, notifications, offline/local storage
- **Packages/Tools:** flutter_bloc, go_router, get_it, dio/http, Hive, sqflite, shared_preferences
- **Practices:** Responsive UI, Arabic/English localization, Git/GitHub, debugging and performance tuning

## Professional Experience
### Flutter Developer — Digital Transformation Center
**Sep 2021 – Present**
- Design and develop cross-platform Flutter applications with maintainable architecture and reusable components.
- Implement business workflows, modern UI, and backend integrations with focus on performance and reliability.
- Collaborate with cross-functional teams to translate operational requirements into production-ready releases.

### Flutter Developer — Information System Institute for Armed Forces
**Sep 2020 – Sep 2021**
- Built and maintained Flutter applications with API integrations and user-focused interfaces.
- Improved app quality through practical architecture decisions, testing cycles, and iterative delivery.
- Contributed to multiple internal projects while strengthening Flutter engineering fundamentals.

### PHP Developer — Traivis Company
**Mar 2020 – Nov 2020**
- Developed server-side features and database-driven modules for an e-learning platform.
- Worked with product and design stakeholders to deliver secure, scalable web functionality.

## Projects

### 1) MECMS Fingerprint Attendance & Center Management Platform (Flutter + Firebase)
**Source:** `/workspace` (current repository; commits by Cursor Agent + Mohamed Salah)  
**Problem:** Education centers needed one system for student data, group scheduling, and attendance tracking linked to fingerprint devices.  
**Key Contributions:**
- Built a role-based Flutter admin platform with modules for stages, grades, subjects, classrooms, teachers, students, parents, groups, schedules, enrollments, attendance, users, and device management.
- Implemented dashboard KPIs for daily attendance, late/absent status, fingerprint punches, and device health.
- Added attendance logic for present/late/absent/excused states, session windows, and carry-over handling for back-to-back sessions.
- Integrated Firebase Auth + Firestore data flows with CRUD streams and responsive bilingual UI (Arabic/English).
**Technologies:** Flutter, Dart, BLoC, go_router, Firebase Auth, Cloud Firestore, Firebase Hosting  
**Measurable Technical Scope (from repo):**
- 15+ admin routes/pages wired in router.
- Large feature expansion in latest commit (`68 files changed`, `17,734 insertions`).

### 2) ZKTeco K50 Pro Sidecar Sync Service (Python FastAPI)
**Source:** `/workspace/zk_sidecar`  
**Problem:** Browser-hosted admin apps cannot directly and reliably communicate with LAN fingerprint devices on ZKTeco protocol/port 4370.  
**Key Contributions:**
- Built a local FastAPI sidecar that bridges Flutter admin actions to ZKTeco devices and syncs punches to Firestore.
- Added connection diagnostics, device user loading, and sync controls (single device, all devices, and auto-sync loop).
- Implemented attendance classification (present/late), clock-skew correction, and automatic absence marking after session end.
- Added startup/autostart scripts and operational documentation for real deployment environments.
**Technologies:** Python, FastAPI, pyzk, httpx, Firebase REST APIs, Firestore  
**Measurable Technical Scope (from repo):**
- 6 operational API endpoints (`/health`, `/test-connection`, `/device-users`, `/sync`, `/sync-loop/start`, `/sync-loop/stop`).
- Auto-sync loop with configurable polling interval (default `30s` in config template).

### 3) Firebase Data Seeding & Environment Bootstrap Scripts
**Source:** `/workspace/tools`  
**Problem:** Admin/teacher demos and QA required fast provisioning of consistent academic and attendance datasets.  
**Key Contributions:**
- Built scripting utilities to seed authentication users and Firestore collections for centers, branches, stages, grades, subjects, classrooms, teachers, groups, schedules, students, and enrollments.
- Automated repeatable setup for local demos and validation of dashboard/attendance scenarios.
**Technologies:** Node.js, Firebase SDK/REST APIs, JavaScript, PowerShell  
**Measurable Technical Scope (from repo):**
- Scripted writes across 10+ Firestore collections with repeatable setup flow.

### Additional Previous Projects (from existing CV)
- **ElMola (Google Play):** Family digital library app with browse, details, and downloadable books for offline reading.
- **House Made (Google Play):** Marketplace app for home-based businesses with product browsing, cart, and in-app payment flow.
- **Her Station (App Store):** Beauty salon booking app with service discovery, reviews, booking, and in-app payment.
- **ID Scanner (GitHub):** App for scanning Egyptian national IDs from camera/gallery and extracting data through API integration.
- **Barcode Scanner (GitHub):** Barcode scanner with category-based local storage using Hive.

## Certifications
- Deep Dive into Clean Architecture in Flutter — Udemy (2024)
- Flutter Payment Integration: Stripe, PayPal & More! — Udemy (2024)
- Mastering Flutter: Responsive & Adaptive UI Design — Udemy (2024)
- Master Git & GitHub: Essential Skills for Developers — Udemy (2024)
- Flutter Advanced Course: Bloc and MVVM Pattern — Udemy (2023)
- Complete Flutter & Dart Development Course — Udemy (2023)
- Full Stack Development Diploma — Russian Cultural Center (2020)

## Education
- ITI Monufia Branch — 3-Month Intensive Training Program, PHP Full-Stack Web Development (2021)
- Bachelor of Commerce — University of Tanta (2017)
