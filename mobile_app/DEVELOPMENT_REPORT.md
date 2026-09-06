# Legal Metrology App — Development Report (Member 3 / Flutter)

**Project:** Automation of Implementation of Legal Metrology Act, 2011 (SIH)
**Deliverable:** Flutter Android APK serving **Inspector** and **Business/Retailer** roles
**Location:** `legal_metrology/` (this folder is the complete Flutter project)

---

## A. Project structure

```
legal_metrology/
  android/                          Android config (minSdk 23, compileSdk 36, permissions)
  pubspec.yaml                      Dependencies (pinned stable)
  README.md                         Quick start + integration guide
  DEVELOPMENT_REPORT.md             This document
  lib/
    main.dart                       App entry (ProviderScope + go_router)
    core/
      constants/app_constants.dart  API_BASE_URL (--dart-define), timeouts, storage keys
      constants/mock_ids.dart       Demo ID generators (INSP-2026-xxxxx, LM/2026/xxxx …)
      theme/app_theme.dart          Material 3 LIGHT GovTech theme (blue/green/neutral)
      errors/app_exception.dart     Typed exception hierarchy, human-readable messages
      errors/error_mapper.dart      Dio/HTTP → typed exception mapping (401/403/404/5xx…)
      network/api_client.dart       TokenStorage (secure) + Dio client + bearer + 401 refresh
      auth/auth_controller.dart     Session state, login/logout/restore, 401 handler
      routing/app_router.dart       go_router: guards, role-based redirects, 40x handling
      widgets/common_widgets.dart   AppScaffold, PrimaryButton, SecondaryButton, StatusChip,
                                    InfoCard, StatCard, QuickAction, LoadingView, ErrorView,
                                    EmptyState, ConfirmationDialog, BottomActionBar,
                                    StepIndicator, AIConfidenceIndicator, EvidenceCard
      widgets/feature_widgets.dart  ViolationCard, NoticeCard, TimelineItem,
                                    PrivateDataBanner, AiAssistanceBanner, ImagePreview
    models/                         user, business, product, inspection, evidence,
                                    ocr_result, violation, offence_history, notice(+case),
                                    self_check, payment, supply_chain, signature
    repositories/                   Capability interfaces (NO implementations):
                                    auth, business, inspection, evidence, ocr, violation,
                                    offence, notice, seizure+case, business_side
                                    (self-check, business cases, payment, supply chain)
    data/
      mock_data.dart                Realistic Indian seed data (businesses, products,
                                    violations, cases, notices, offence history, payments)
      mock_backend.dart             In-memory NestJS+FastAPI simulator — stateful, RBAC,
                                    latency, OCR pipeline stages, ~12% OCR failure rate
      mock/mock_repositories.dart   14 Mock*Repository implementations
      real/real_repositories.dart   14 Real*Repository implementations (provisional routes)
    services/
      camera_service.dart           Permission lifecycle (granted/denied/permanent)
      signature_service.dart        SignatureService abstraction (eMudhra swap point)
    di/providers.dart               ★ THE Mock ⇄ Real switch + all Riverpod wiring
    features/
      auth/         splash, login (role tabs + demo creds), register (business only),
                    unauthorized screen
      inspector/    inspector_shell (bottom nav), dashboard, business_search (+start-
                    inspection sheet), inspections list/detail, inspection/ 8-step flow
                    (evidence → ocr → ocr_review → violations → offence → observations
                    → notice → signature → complete), cases list/detail (timeline),
                    add_violation_sheet, supplier_declaration_sheet, seizure sheet
      business/     business_shell, dashboard (prevention hero), self_check,
                    self_check_history, notices inbox, notice detail (correction/
                    dispute/consent/pay), cases (timeline), payments
      shared/       camera_capture_screen — in-app camera, full permission lifecycle
  test/widget_test.dart             8 passing tests (auth, repositories, app smoke)
```

**Line-count discipline:** no 1000+ line widgets; each screen/step is a focused file.

---

## B. Packages used and why

| Package | Version | Why |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management + DI; repositories provided as providers, swappable |
| `dio` | ^5.7.0 | REST client with interceptors (bearer injection, 401 refresh-once) |
| `go_router` | ^14.6.2 | Declarative routing, `StatefulShellRoute` bottom-nav, redirects/guards |
| `flutter_secure_storage` | ^9.2.2 | JWT storage in Android Keystore-backed EncryptedSharedPreferences |
| `camera` | ^0.11.0+2 | In-app guided capture screen (full control over viewfinder/UX) |
| `image_picker` | ^1.1.2 | Gallery fallback + multi-image attach (correction submissions) |
| `permission_handler` | ^11.3.1 | Camera permission lifecycle incl. permanently-denied → Settings |
| `intl` | ^0.20.1 | `en_IN` currency (₹), Indian date formats |
| `signature` | ^5.5.0 | Signature pad PNG capture (prototype) |
| `connectivity_plus` | ^6.1.1 | Network reachability groundwork (not yet wired to UI) |

*Note:* `file_picker` (recommended in the brief) is intentionally **not included
yet** — nothing attaches non-image documents in the mock flows, and the 8.x
line pins `compileSdk 34` which breaks the SDK-36 toolchain. The integration
point is documented in `pubspec.yaml`; add the 10.x/11.x line when invoice/
document attachments move to the live backend.

---

## C. Authentication implementation

- **Interface:** `AuthRepository` (login, refresh, currentUser, logout,
  registerBusinessAccount) — designed for Keycloak OIDC via NestJS.
- **RBAC:** `UserRole.inspector | business` from the backend, never chosen by
  the user at login. **Inspector self-registration is impossible** — the
  register screen explicitly states inspectors are department-provisioned.
- **Session:** `AuthController` (StateNotifier) restores the session from
  secure storage at splash; router redirects on every auth-state change.
- **Tokens:** access+refresh stored via `TokenStorage` (secure storage only —
  never plain text). Dio interceptor injects `Authorization: Bearer`; on 401
  it attempts a **single** refresh then retries, else surfaces
  `UnauthorizedException` → session cleared → redirect to login.
- **403** maps to a friendly `ForbiddenException`; unauthorized route access
  renders a dedicated `UnauthorizedScreen`.
- **Mock:** demo accounts (`rajesh.deshmukh`/`inspector123`,
  `anita@abctraders.in`/`business123`). Real Keycloak config slots in by
  flipping `REAL_AUTH` dart-define — zero UI changes.

## D. Inspector feature list

1. **Dashboard** — greeting, assigned-inspections/active-cases/draft-notices/
   pending-actions stat cards, quick actions (Start Inspection / Search
   Business / My Inspections), today's inspections, notices requiring action.
2. **Business search** — name/GSTIN/owner/city; result cards with GSTIN,
   address, status chips; **Start Inspection** bottom sheet (type: Routine /
   Complaint-Based / Supply-Chain-Linked; complaint ID field; backend issues
   the inspection ID).
3. **Guided inspection flow (8 steps + completion):**
   1. *Evidence capture* — guided Front/Back/Side slots, unlimited additional
      photos, retake/delete/preview, "Capture 2–3 clear sides" guidance.
   2. *OCR processing* — 5-stage pipeline UI (Uploading Evidence → Processing
      Images → Extracting Text → Identifying Declarations → Checking
      Compliance) with per-stage progress; retry on failure.
   3. *OCR result review* — every extracted field **editable**, missing fields
      addable, incorrect fields removable, per-field AI-confidence chips,
      low-confidence warnings, raw-text preview; "AI/OCR EXTRACTED — VERIFY
      BEFORE PROCEEDING" banner; Confirm Information gate.
   4. *AI violation review* — findings arrive as **POTENTIAL**; per-finding
      **Accept / Reject / Edit**; manual **Add Violation** with Legal-KB
      section picker; live potential/confirmed/rejected counters;
      human-in-the-loop banner.
   5. *Offence history* — backend product-match result: tier badge (Second
      offence in demo for Surf Excel @ ABC Traders), matched product +
      confidence, previous case records (case/business/location/date/status);
      clean "No previous offence" state.
   6. *Observations* — product/batch/quantities/MRPs/manufacturer/supplier/
      remarks; **Declare Supplier / Source** sheet (supply-chain declaration
      through NestJS); **Record Seizure / Sample** sheet (quantity, reason,
      sample photo, two witnesses, remarks; backend-issued sample ID).
   7. *Notice generation & review* — type selection (Improvement/Seizure/
      Compounding/Panchanama), AI/NLP draft with **"AI-GENERATED DRAFT —
      INSPECTOR VERIFICATION REQUIRED"**, editable body + remarks, cited
      sections list with **Add Section** from the Legal-KB library,
      deadlines; confirm → proceed to signature.
   8. *Signature & issue* — drawn-signature pad (clear/signing-as name),
      prototype disclaimer (NOT an eMudhra signature), Sign & Issue →
      completion screen.
4. **Cases** — case list with status chips; **Case Detail** with required-
   action banner and the full visual **timeline** (done/current/pending,
   actors, details) — only backend-returned states rendered.

## E. Business feature list

1. **Dashboard** — welcome header, **PREVENTIVE COMPLIANCE hero**
   ("Check your packaging before you sell" → Scan Packaging CTA), stats
   (active cases, pending notices, pending amount, compliance), quick
   actions, private-data banner, sign-out.
2. **Self compliance check** — capture/add package photos, optional product
   name, pipeline progress, **PRIVATE** banner throughout; result screen:
   COMPLIANT or POTENTIAL ISSUES FOUND with per-issue field/issue/
   REQUIREMENT/severity/**recommended correction** in plain language.
3. **Self-check history** — private reports with result chips and issue
   summaries; clearly labelled PRIVATE.
4. **Notice inbox** — type/case/product/date/deadline/status cards.
5. **Notice detail** — body text, cited sections, violations cited;
   **status-gated actions**: Submit Correction (comments + photo attach),
   Raise Dispute (reason/comments), Give Consent (explicit confirmation
   dialog), Pay Penalty. Non-actionable states show an explanatory card.
6. **Cases** — per-case timeline (Inspection → Notice → Response →
   Correction/Re-inspection → Compounding → Payment → Closure), deadlines,
   required actions.
7. **Payments** — pending + history, ₹ `en_IN` formatting, **Check Status**
   polling (backend verification is the only success source), explicit note
   that the department confirms payments after gateway verification.

## F. Mock API architecture

- **`MockBackend`** (singleton): in-memory, stateful, seeds realistic data;
  enforces RBAC (`requireRole`), throws typed exceptions, simulates latency
  (0.2–1.4 s per op), runs a staged OCR pipeline with a small realistic
  failure rate, advances notice statuses on business actions (correction →
  `complianceSubmitted`, dispute → `underDispute`, consent → `consentGiven`),
  and simulates payment webhook verification across status polls.
- **14 Mock repositories** implement every capability interface against the
  backend; **14 Real repositories** implement the same interfaces with
  provisional NestJS routes (single file to update when Member 1 finalises).
- **Switch:** `di/providers.dart` — `useMockData` (default true) +
  per-capability `REAL_AUTH` / `REAL_OCR` dart-defines for incremental
  migration. UI code never knows which is active.

## G. Backend capabilities required from Member 1 (NestJS)

| Capability | provisional route (real_repositories.dart) |
|---|---|
| Login / refresh / me / logout / business register | `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`, `POST /auth/logout`, `POST /auth/register/business` |
| Business search/get/register/update | `GET /businesses?q=`, `GET/POST/PATCH /businesses[/:id]` |
| Inspection CRUD + start/complete/observations | `GET/POST /inspections`, `POST /inspections/:id/start|complete`, `PATCH /inspections/:id/observations` |
| Evidence upload/list/delete | `POST/GET /inspections/:id/evidence`, `DELETE /evidence/:id` |
| OCR passthrough (FastAPI) | `POST /ocr/analyze` (multipart → jobId), `GET /ocr/jobs/:jobId` (status+result) |
| Violations | `GET/POST /inspections/:id/violations`, `PATCH /violations/:id`, `POST /violations/:id/confirm|reject` |
| Offence history (product match) | `GET /products/:productId/offences?businessId=` |
| Notices | `POST /notices/generate`, `GET /notices/:id`, `GET /businesses/:id/notices`, `GET /inspector/notices`, `PATCH /notices/:id`, `POST /notices/:id/sections|confirm|issue` |
| Seizure / panchanama | `POST/GET /inspections/:id/seizures`, `POST /panchanamas`, `GET /inspections/:id/panchanama` |
| Cases + timeline | `GET /cases[?active=true]`, `GET /cases/:id` |
| Self-check (private scope) | `POST /self-check/analyze` (multipart), `GET /self-check/history` |
| Business responses | `POST /notices/:id/correction|dispute|consent`, `GET /business/notices`, `GET /business/cases` |
| Payments | `POST /payments/initiate`, `GET /payments/:id`, `GET /payments` |
| Supply chain | `POST /inspections/:id/supply-chain`, `POST /inspections/:id/supply-chain/evidence` |

Expectations: JWT bearer auth, role claims in token, images accepted as
multipart, IDs returned server-side (inspections, notices, cases, samples).

## H. OCR/AI response fields required from Member 4

Job envelope: `jobId`, `status` (PROCESSING/COMPLETED/FAILED),
`progressStep` (one of the 5 pipeline steps), `failureReason`,
`rawTextPreview` (optional).

`fields[]` per analyzed package — each with `key`, `label`, `value`,
`confidence` (0–1), `isMissing`, optional `sourceImageId`, `unit`:

`PRODUCT_NAME`, `GENERIC_NAME`, `MANUFACTURER`, `PACKER`, `IMPORTER`,
`NET_QUANTITY`, `MRP`, `MANUFACTURING_DATE`, `EXPIRY_USE_BY`,
`COUNTRY_OF_ORIGIN`, `CONSUMER_CARE`, `BATCH_LOT`, `OTHER`.

Violations[]: `id`, `type`, `description`, `severity`
(LOW/MEDIUM/HIGH/CRITICAL), `status: POTENTIAL`, `confidence`,
`ruleSection`, `ruleTitle`, `recommendation`, `sourceImageId`.

Self-check: `isCompliant`, `issues[] {field, issue, requirement, severity,
recommendedCorrection}` (plain-language strings for business users).

Offence lookup: `matchedProductName`, `tier` (NONE/FIRST/SECOND/REPEAT),
`matchConfidence`, `records[] {caseId, businessName, location, date,
violationSummary, caseStatus}`.

## I. Legal-rule fields required from Member 5

The UI consumes a section library matching `NoticeSection`:
`id`, `citation` (e.g. "Rule 6(3), LM (Packaged Commodities) Rules, 2011"),
`title`, optional `description`. The mock ships 8 representative sections
(Rules 2(m), 6(1), 6(3), 7; Sections 18(1), 22, 32, 46 LM Act 2009).
Additionally: violation→section mapping (arrives attached to AI findings),
notice templates' legal structure, compounding amounts by tier, and
notice-period defaults for panchanama/seizure documents.

## J. Signature/payment integration points required from Member 6

- **Signature:** implement `SignatureService` (`lib/services/signature_service.dart`)
  with eMudhra DSC/eSign; `verifyDigitalSignature()` already throws
  `UnimplementedError` as the hook. Notice issue flow already transmits a
  signature artifact + signer name to the backend.
- **Payments:** `PaymentRepository.initiatePayment` must return
  `{paymentId, orderId, amount, currency, note}` to open Razorpay checkout;
  status is polled via `getPaymentStatus` (PaymentStatus enum mirrors the
  webhook lifecycle: INITIATED → PENDING_VERIFICATION → SUCCESS/FAILED).
  **The app never marks success locally.** A Razorpay Flutter SDK (or
  web-checkout redirect from the backend response) slots into
  `PaymentsScreen` / notice-detail pay action.

## K. Files to modify when replacing Mock API with NestJS

1. `lib/di/providers.dart` — flip `useMockData` (or per-capability defines).
2. `lib/data/real/real_repositories.dart` — align routes + JSON casing to the
   final contract (the only place endpoint paths appear).
3. `lib/core/constants/app_constants.dart` — set the real `API_BASE_URL`
   default (or ship via --dart-define).
4. `lib/core/network/api_client.dart` — point `_tryRefresh()` at the real
   Keycloak token endpoint.
5. `lib/services/signature_service.dart` — eMudhra implementation (Member 6).
6. Optionally remove mock seeding of status flows once live polling works.

**No changes** to screens, controllers, models, or interfaces.

## L. Configuring API_BASE_URL

- Default (emulator → localhost): `http://10.0.2.2:3000/api/v1`
- Override at build/run time:
  `flutter run --dart-define=API_BASE_URL=https://api.example.in/api/v1`
- Defined once in `lib/core/constants/app_constants.dart`; consumed only by
  `ApiClient`.

## M. Running the Android application

```bash
cd legal_metrology
flutter pub get
flutter run                          # demo mode on emulator/device
# or
flutter build apk --debug            # APK at build/app/outputs/flutter-apk/
flutter build apk --release
```

Requirements: Flutter 3.44+/Dart 3.12, Android SDK 36, minSdk 23 (set in
`android/app/build.gradle.kts`), camera permission granted at runtime.
`flutter analyze` → 0 errors/0 warnings; `flutter test` → 8/8 passing.

## N. Switching Demo Mode ON/OFF

- **ON (default):** `flutter run` — everything works offline against
  `MockBackend`; login screen shows demo accounts.
- **OFF:** set `useMockData = false` in `lib/di/providers.dart`, or run with
  `--dart-define=USE_MOCK_DATA=false` plus
  `--dart-define=API_BASE_URL=http://<backend-host>:3000/api/v1`.
- Partial migration: `--dart-define=REAL_AUTH=true` (real Keycloak login,
  mocked data) and/or `--dart-define=REAL_OCR=true`.
- The login screen's "DEMO MODE" helper panel is the only explicitly
  demo-labelled UI; all other screens present production-grade visuals.

---

### Design/UX decisions (judging notes)

- Light Material 3 GovTech theme: institutional blue primary, compliance
  green secondary, amber attention, generous 52 dp CTAs, 16 px cards with
  hairline borders, strong typographic hierarchy, no gradients.
- Every async surface has loading, friendly-error (Retry), and empty states.
- Two core ideas are visually unmistakable: **PREVENTION** (green hero +
  private self-check on the business side) and **ENFORCEMENT** (guided
  8-step inspection flow with human-in-the-loop gates on the inspector side).
- AI never finalises anything: POTENTIAL findings require explicit inspector
  confirmation; notices are drafts until signed; payments wait for backend
  verification.
