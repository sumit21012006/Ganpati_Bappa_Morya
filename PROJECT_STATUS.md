# Stay_Calm - Project Architecture and Status Report
> SIH PS-34: Legal Metrology Act 2009 & Packaged Commodities Rules 2011 Automation
> Generated: 2026-09-07 | Root: e:\SIH_2026\Stay_Calm

---

## 1. What This System Does

Automates legal metrology field enforcement. Inspector photographs packaged goods,
OCR extracts packaging declarations, AI compliance engine checks against LM (PC) Rules 2011,
generates statutory government notices (PDF + DOCX), captures digital signature,
records everything in live database -- end-to-end on a mobile device, no paper.

## 2. Roles & Platforms

| Role | Platform | Purpose |
|------|----------|---------|
| Inspector | Flutter mobile | Inspections, photos, violations, issues notices |
| Business | Flutter mobile | Receives notices, self-check, payments |
| Controller | Next.js web | Command dashboard, compounding, supply chain |
| Citizen | Next.js web | Files complaints with photo evidence |

## 3. Tech Stack

```
Backend  : FastAPI + Python, SQLAlchemy, Alembic, SQLite/PostgreSQL
           Groq LLaMA-3.3-70B for OCR parsing, python-docx, ReportLab
Mobile   : Flutter/Dart 3, Riverpod 2.6, Go Router 14, Dio 5.7
           Camera, ML Kit OCR, Signature, pdf/printing, Secure Storage
Web      : Next.js 16.3, React 19, TypeScript 5, Tailwind CSS 4
           Recharts, Leaflet, Lucide React
Knowledge: Legal Metrology Master Rulebook v2.0
           23 rules, 15 mandatory fields, compounding matrix, exemptions
```

## 4. Directory Structure

```
Stay_Calm/
  .env                         Runtime secrets (GROQ_API_KEY, DATABASE_URL)
  legal_metrology.db           Local SQLite dev fallback (81 KB)
  ARCHITECTURE_AND_FLOW.md     Original architecture doc (383 lines)
  PROJECT_STATUS.md            This file
  Knowledgebase/
    rulebook.json              23 rules, 15 mandatory fields (67 KB)
    compounding_matrix.json    Penalty computation table
    exemptions.json            Category exemption rules
    penalty_matrix.json        First/second offence bands
    legal_sources.json         Act/Rule citation database
  alembic/versions/
    007ebe81a18e_baseline_schema.py
    75879f7fbb4e_add_ps34_models_and_fields.py
  backend/
    server.py                  108 KB, ~2200 lines, 65 API routes
    models.py                  10 SQLAlchemy ORM tables (279 lines)
    database.py                Engine + session (PostgreSQL/SQLite dual)
    notice_service.py          PDF/DOCX generation (37 KB)
    ocr_service.py             Groq OCR pipeline (15 KB)
    rule_engine.py             LegalComplianceEngine (13 KB)
    integrations.py            eMudhra, Razorpay, MinIO, RabbitMQ stubs
  mobile_app/lib/
    main.dart
    core/auth/, constants/, errors/, network/, routing/, widgets/
    data/real/real_repositories.dart    Live API layer (41 KB)
    data/mock/mock_repositories.dart    Test doubles
    di/providers.dart                   Riverpod DI wiring
    features/auth/                      Login, Register, Splash
    features/business/                  Dashboard, Notices, Cases, Payments, Self-check
    features/inspector/                 Dashboard, Search, Inspections, 9-step wizard
    models/                             14 domain model Dart files
    repositories/                       10 abstract repository interfaces
    services/
      compliance_engine.dart            Flutter-side 23-rule checker (17 KB)
      notice_pdf_generator.dart         On-device PDF rendering (36 KB)
      ocr_service.dart                  ML Kit + Groq pipeline (27 KB)
      signature_service.dart
  sih-web/src/
    app/page.tsx                        Unified multi-role SPA (2726 lines / 164 KB)
    app/api/auth/                       Next.js Login + Register API routes
    components/
      CitizenComplaintForm.tsx          Full complaint filing (40 KB)
      JurisdictionAnalyticsGraphs.tsx   Recharts charts (23 KB)
      LeafletRadarMap.tsx               Geospatial map (10 KB)
      Header, Sidebar, Footer, LoginPortal
    context/AppContext.tsx              Global state (user, role, tabs, notifications)
    lib/api/ (auth, businesses, complaints, controller, notices)
```

## 5. Database Schema (10 Tables)

| Table | Key Columns | Status |
|-------|-------------|--------|
| users | id, name, email, role (INSPECTOR/BUSINESS/CONTROLLER/CITIZEN), badge_id | Live |
| businesses | id, trade_name, address, gstin, owner_user_id | Live |
| inspections | id, business_id, inspector_id, status, inspection_type | Live |
| inspection_products | id, inspection_id, commodity_name, mrp, net_qty, mfg_date, expiry_date | Live |
| violations | id, inspection_product_id, rule_id, title, legal_section, severity | Live |
| notices | id, inspection_id, notice_type, status (controller), payment_status (issuance) | Live (dual-status debt) |
| complaints | id, citizen_id, store_name, product_name, photo_urls, status, channel | Live |
| supply_chain_links | id, inspection_id, upstream_business_name | Live |
| audit_logs | id, user_id, action, entity_type, entity_id | Live |
| self_check_analyses | id, business_id, product_name, compliance_score, violations_json | Live |

## 6. All 65 API Endpoints

### Auth (5) - All working
- POST /api/v1/auth/login
- POST /api/v1/auth/register
- POST /api/v1/auth/register/business
- GET  /api/v1/auth/me
- POST /api/v1/auth/logout

### Business Discovery (3) - All working
- GET /api/v1/businesses
- GET /api/v1/businesses/search
- GET /api/v1/businesses/{id}

### OCR (3) - All working
- POST /api/v1/ocr/analyze  (Groq LLM + ML Kit fallback)
- POST /api/v1/ocr/extract-packaging
- GET  /api/v1/ocr/jobs/{job_id}

### Inspections (6) - All working
- POST /api/v1/inspections
- GET  /api/v1/inspections
- GET  /api/v1/inspections/{id}
- POST /api/v1/inspections/{id}/start
- POST /api/v1/inspections/{id}/complete
- POST /api/v1/inspections/{id}/scan

### Violations (5) - All working
- GET  /api/v1/inspections/{id}/violations
- POST /api/v1/inspections/{id}/violations
- POST /api/v1/violations/{id}/confirm
- POST /api/v1/violations/{id}/reject
- PATCH /api/v1/violations/{id}

### Notice Pipeline (10) - PARTIALLY BROKEN
- POST /api/v1/notices/generate        WORKING - generates real PDF + DOCX
- POST /api/v1/notices/{id}/issue      BROKEN BUG-B1: missing async keyword -> 500
- GET  /api/v1/notices/{id}            Working (pdfUrl not pdfPath - BUG-B2)
- PATCH /api/v1/notices/{id}           Working
- GET  /api/v1/notices                 Working
- POST /api/v1/notices/{id}/sections   Working
- POST /api/v1/notices/{id}/confirm    Working
- GET  /api/v1/notices/download/{f}    Working
- GET  /api/v1/inspector/notices       Working (pdfUrl not pdfPath - BUG-B2)
- GET  /api/v1/business/notices        Working (pdfUrl not pdfPath - BUG-B2)

### Cases (3) - All working
- GET /api/v1/cases
- GET /api/v1/cases/{id}
- GET /api/v1/business/cases

### Business Notice Response (3) - All working
- POST /api/v1/notices/{id}/correction
- POST /api/v1/notices/{id}/dispute
- POST /api/v1/notices/{id}/consent

### Seizure and Supply Chain (5) - All working
- POST /api/v1/inspections/{id}/seizures
- GET  /api/v1/inspections/{id}/seizures
- POST /api/v1/inspections/{id}/supply-chain
- POST /api/v1/inspections/{id}/supply-chain/evidence
- GET  /api/v1/supply-chain/trace/{gstin}

### Offence History (1) - Working
- GET /api/v1/products/{product_id}/offences

### Payments (3) - STUBS ONLY
- GET  /api/v1/payments
- POST /api/v1/payments/initiate
- POST /api/v1/payments/create-penalty-order  (Razorpay format ready, no live key)

### Self-Check (2) - All working
- POST /api/v1/self-check/analyze
- GET  /api/v1/self-check/history

### Controller (4) - All working
- GET  /api/v1/controller/dashboard/stats
- POST /api/v1/controller/compounding/{id}/action  (APPROVE/REJECT/PROSECUTION)
- GET  /api/v1/controller/supply-chain-links
- PATCH /api/v1/controller/supply-chain-links/{id}/assign

### Citizen and Misc (4)
- POST /api/v1/complaints                    Working
- GET  /api/v1/complaints                    Working (role-filtered)
- POST /api/v1/signatures/sign-document      STUB (eMudhra format ready)
- GET  /api/v1/audit-logs                    Working

## 7. Mobile App - 9-Step Inspection Wizard Status

| Step | Label | Widget | Status |
|------|-------|--------|---------|
| 0 | Evidence | EvidenceStep | WORKING - multi-photo camera |
| 1 | OCR | OcrStep | WORKING - Groq + ML Kit |
| 2 | Fields | OcrReviewStep | WORKING - edit extracted fields |
| 3 | Violations | ViolationsStep | WORKING - 23 rules, no mock |
| 4 | Offence History | OffenceStep | WORKING - live backend lookup |
| 5 | Observations | ObservationsStep | WORKING - supplier + seizure |
| 6 | Notice | NoticeStep | PARTIAL - draft OK, pdfPath always null (BUG-B2) |
| 7 | Sign | SignatureStep | BROKEN - backend 500 crash (BUG-B1) |
| 8 | Done | FlowCompleteScreen | BROKEN - receives null notice from Step 7 |

## 8. All Mobile Screens

Inspector: Login, Register, Splash (WORKING)
Inspector: Dashboard, Business Search, Inspections, Cases (WORKING)
Inspector: 9-step wizard Steps 0-5 (WORKING), Steps 6-8 (BROKEN - 3 bugs)
Business: Dashboard, Notices List+Detail, Cases, Self-Check, History (WORKING)
Business: Payments screen (UI done, Razorpay not live)

## 9. Web Dashboard Screens

Controller (all working):
  Login/Register, Command Dashboard (live stats), Jurisdiction Radar Map,
  Analytics Graphs, Compounding Queue, Supply Chain, Notification Bell

Citizen (all working):
  Complaint Filing with photo upload, My Complaints List, Register

## 10. Notice Generation System

4 official government notice types (all working):
  1. Improvement Notice   - generate_improvement_notice()
  2. Compounding Order    - generate_compounding_order()
  3. Seizure Bill         - generate_seizure_bill()
  4. Panchanama           - generate_panchanama()

Multi-notice: inspector selects multiple types, generates individual PDFs + combined bundle.
Digital signature stamp applied with eMudhra token format.
On-device PDF also generated by notice_pdf_generator.dart (Flutter).

## 11. OCR Pipeline

Photo -> /api/v1/ocr/analyze
      -> ML Kit on-device text extraction
      -> Groq LLaMA-3.3-70B statutory parser
      -> Extracted: product_name, mrp, net_qty, mfg_date, expiry_date,
                    manufacturer, consumer_care, batch_no, country_of_origin
      -> ComplianceEngine checks 23 rules from rulebook.json
      -> Violations as POTENTIAL (inspector must accept/reject each one)

## 12. Third-Party Integration Status

| Service | Status |
|---------|--------|
| eMudhra DSC | STUB - token format ready, USB hookup pending |
| Razorpay / GRAS | STUB - order structure ready, no live key |
| MinIO / S3 | STUB - local disk active, switch available |
| RabbitMQ | STUB - in-memory fallback active |
| Neo4j | NOT STARTED - supply chain is SQL only |
| DocuSign | MOCK - format correct, no live API key |

## 13. Active Bugs (Root Cause of Steps 6-8 Broken)

BUG-B1 [CRITICAL] backend/server.py in issue_notice() function:
  Missing async keyword. Crashes with HTTP 500 when signature file is uploaded.
  Fix: change 'def issue_notice(' to 'async def issue_notice('

BUG-B2 [CRITICAL] All notice-returning backend functions:
  Backend returns key 'pdfUrl' but Flutter _parse() reads key 'pdfPath'.
  PDF is always null - no download button appears.
  Fix: add 'pdfPath': pdf_url alongside 'pdfUrl' in format_notice_for_client()
       and in generate_notice() notice_dict

BUG-B3 [MODERATE] backend/server.py issue_notice() fallback path:
  When notice not found in DB, fallback return is missing:
  isAiDraft, businessId, businessName, inspectionId, pdfPath
  Fix: add these 5 fields to the fallback return dict

BUG-B4 [DESIGN DEBT] NoticeModel:
  payment_status overloaded as issuance marker (UNPAID/PAID/ISSUED).
  Not a crash - format_notice_for_client handles it - but confusing.

## 14. Completion Status

DONE (100%):
  Auth (JWT, 4 roles), Business registration+lookup, Inspector dashboard
  Inspection creation+management, OCR pipeline, Compliance engine (23 rules)
  Violation CRUD, Offence history, Case management, Business self-check
  Business notice response, Controller compounding+supply chain
  Citizen complaints, Seizure+panchanama, Supply chain recording, Audit logs
  Web analytics+charts, Leaflet map, Notification system, Legal knowledgebase
  Alembic migrations, PostgreSQL+SQLite dual support

PARTIAL:
  Notice generation (95%) - pdfPath key mismatch bug
  Notice signing (70%) - async keyword missing in backend
  Payments screen UI (done, Razorpay not live)

NOT DONE (0%):
  Payment gateway (Razorpay live) - needs live API key + GRAS onboarding
  eMudhra real DSC - needs government DSC token
  DocuSign live wiring - needs API key
  Neo4j supply chain graph - not started
  Push notifications (FCM)
  MinIO cloud storage (local disk is active fallback)
  Production deployment (Docker/Railway/Render)
  Unit and integration tests (only test_ocr.py exists)

## 15. Running the System

Backend:  python -m uvicorn backend.server:app --host 0.0.0.0 --port 8000 --reload
Web:      cd sih-web && npm run dev
Mobile:   cd mobile_app && flutter run -d <device_id>
API URL:  Set in mobile_app/lib/core/constants/app_constants.dart

## 16. Immediate Fixes (3 bugs, all in backend/server.py)

Fix 1 - BUG-B1: Add async to issue_notice function declaration
Fix 2 - BUG-B2: Add pdfPath key to format_notice_for_client() return dict
Fix 3 - BUG-B2: Add pdfPath key to generate_notice() notice_dict
Fix 4 - BUG-B3: Add isAiDraft, businessId, businessName, inspectionId, pdfPath to issue_notice fallback return

---
Last updated: 2026-09-07
Full audit of e:\SIH_2026\Stay_Calm
65 API routes, 10 DB tables, 14 Flutter models, 2726-line web portal
