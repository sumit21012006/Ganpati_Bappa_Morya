# Legal Metrology — Flutter App (Inspector + Business)

SIH project: **Automation of Implementation of Legal Metrology Act, 2011**.

This Flutter APK serves the **INSPECTOR** and **BUSINESS/RETAILER** roles.
Controller and Citizen web portals are separate Next.js apps (Member 2).
All data flows through the **NestJS** backend (Member 1) — this app NEVER
connects to PostgreSQL directly.

```
Flutter APK (this repo)  →  NestJS (Member 1)  →  PostgreSQL 16 + PostGIS
                                  ↓
                          FastAPI AI service (Member 4)
```

## Quick start

This app lives in the `mobile_app/` folder of the team repository.
All other folders (Research, Task_Distribution, shared schema docs) belong to the team's documentation.

```bash
cd mobile_app
flutter pub get
flutter run                 # runs in DEMO MODE (mock repositories, no backend needed)
```

### Demo credentials

| Role      | Username             | Password       |
|-----------|----------------------|----------------|
| Inspector | `rajesh.deshmukh`    | `inspector123` |
| Business  | `anita@abctraders.in`| `business123`  |

The login screen also shows these accounts; tapping the role tabs prefills them.

### Run on a physical Android device

```bash
flutter build apk --debug       # or --release
flutter install
```

## Demo Mode ON/OFF

| Mode | Command |
|------|---------|
| **Demo (mock)** — default, no backend needed | `flutter run` |
| Real backend (all repos) | set `useMockData = false` in `lib/di/providers.dart` **or** add a `REAL_*` dart-define (see below) |
| Real auth only (rest mocked) | `flutter run --dart-define=REAL_AUTH=true --dart-define=API_BASE_URL=http://<host>:3000/api/v1` |
| Real OCR only | `flutter run --dart-define=REAL_OCR=true --dart-define=API_BASE_URL=...` |
| Point to a different backend | `--dart-define=API_BASE_URL=https://api.yourhost.in/api/v1` |

`API_BASE_URL` defaults to `http://10.0.2.2:3000/api/v1` (Android emulator → host machine).

## Architecture

```
lib/
  core/
    constants/     app_constants.dart (API_BASE_URL), mock_ids.dart
    theme/         app_theme.dart — Material 3 light GovTech theme
    errors/        app_exception.dart (typed errors), error_mapper.dart
    network/       api_client.dart — Dio + TokenStorage (secure) + 401 refresh
    auth/          auth_controller.dart — session, role state
    routing/       app_router.dart — go_router, role-protected routes
    widgets/       common_widgets.dart, feature_widgets.dart — reusable UI
  models/          user, business, product, inspection, evidence,
                   ocr_result, violation, offence_history, notice,
                   self_check, payment, supply_chain, signature
  repositories/    interfaces ONLY (auth, business, inspection, evidence,
                   ocr, violation, offence, notice, seizure, case,
                   business-side: self-check/cases/payment/supply-chain)
  data/
    mock_data.dart     realistic Indian seed dataset
    mock_backend.dart  in-memory NestJS+FastAPI simulator (stateful)
    mock/              Mock*Repository implementations
    real/              Real*Repository implementations (provisional routes)
  services/        camera_service.dart (permissions), signature_service.dart
  di/providers.dart  ← THE Mock ⇄ Real switch (one file)
  features/
    auth/          splash, login, register, unauthorized
    inspector/     dashboard, business_search, inspections, inspection flow
                   (evidence → OCR → review → violations → offence →
                    observations → notice → signature), cases, timeline
    business/      dashboard, self_check (+history), notices (+detail),
                   cases, payments
    shared/        camera_capture_screen (permission-safe in-app camera)
  main.dart
```

### Dependency rule

```
UI (screens)  →  Controllers/state  →  Repository interface
                                             ↓
                          Mock implementation (demo)  /  Real implementation (NestJS)
```

UI never imports mock data or Dio directly — swap implementations freely.

## Human-in-the-loop principle (enforced in UI)

- AI findings arrive as **POTENTIAL**; inspectors must Accept / Reject / Edit each one.
- Notices are **AI-GENERATED DRAFTS** until reviewed, edited, signed, and issued.
- Self-checks are **PRIVATE** — never create cases/offences.
- Payments are confirmed **only by backend verification** (Razorpay webhook).

## Backend integration notes

- All provisional NestJS routes live in `lib/data/real/real_repositories.dart`.
- Final endpoint names are Member 1's decision — only that file changes.
- OCR response schema expected: job id → status polling → structured fields
  (see `lib/models/ocr_result.dart` doc comment for the expected JSON).
