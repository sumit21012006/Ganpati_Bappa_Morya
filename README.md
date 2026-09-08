# ⚖️ Legal Metrology Automated Enforcement Core Engine
### Smart India Hackathon (SIH 2026) | Problem Statement 34
> **Digital Transformation of Statutory Enforcement under the Legal Metrology Act, 2009 & Legal Metrology (Packaged Commodities) Rules, 2011.**

[![FastAPI](https://img.shields.io/badge/Backend-FastAPI_0.109-009688.svg?logo=fastapi)](https://fastapi.tiangolo.com)
[![Next.js](https://img.shields.io/badge/Web_Portal-Next.js_16_(Turbopack)-black.svg?logo=next.js)](https://nextjs.org)
[![Flutter](https://img.shields.io/badge/Mobile_App-Flutter_3.x-02569B.svg?logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL_16-336791.svg?logo=postgresql)](https://www.postgresql.org)
[![LLM OCR](https://img.shields.io/badge/AI_Parser-Groq_LLaMA--3.3--70B-f55036.svg)](https://groq.com)
[![License](https://img.shields.io/badge/Ministry-Consumer_Affairs-darkgreen.svg)](#)

---

## 📌 Executive Summary

Traditional legal metrology enforcement in India relies on manual on-ground market visits, physical paper panchanamas, subjective human assessment of packaging declarations, and disconnected paper notices. Retailers are penalized while rogue upstream manufacturers and packers evade liability due to paper-trail fragmentation.

This **Legal Metrology Automated Enforcement Core Engine** provides an end-to-end, zero-paper ecosystem that empowers:
1. **On-Ground Inspectors** to scan packaged commodities via smartphone cameras, run automated AI compliance checks, generate digital panchanamas with geostamps, and record upstream supply chain declarations.
2. **Central Controllers (Legal Metrology Officers)** to monitor nationwide violations via an interactive GIS command radar, review AI-flagged non-compliances, deploy tactical inspection raids, auto-generate statutory notices with cryptographic signatures (eMudhra DSC), and manage compounding orders.
3. **Businesses & Retailers** to run automated pre-market self-compliance audits on their product labels, receive statutory notices digitally, and settle compounding penalties instantly via integrated UPI / Razorpay gateways.
4. **Citizens & Consumers** to file crowdsourced geotagged violation leads and receive government-backed whistleblower reward bounties funded directly from collected compounding penalties.

---

## 🏛️ System Architecture

```
                                  USER & PRESENTATION LAYER
  ┌───────────────────────┬────────────────────────┬────────────────────────┬───────────────────────┐
  │  CITIZEN / CONSUMER   │  BUSINESS / RETAILERS  │  INSPECTOR (ON-GROUND) │  CENTRAL CONTROLLER   │
  │  [Next.js 16 Web]     │  [Flutter Mobile]      │  [Flutter Mobile]      │  [Next.js 16 Web]     │
  │  • Geotagged Reports  │  • Label Pre-check     │  • Packaging OCR Scan  │  • Command Dashboard  │
  │  • Invoice Upload     │  • Digital Notice Box  │  • 9-Step Inspection   │  • Upstream Traceback │
  │  • Bounty Status      │  • Razorpay UPI Fine   │  • Supply Chain Link   │  • Digital Signature  │
  └──────────┬────────────┴───────────┬────────────┴───────────┬────────────┴───────────┬───────────┘
             │                        │                        │                        │
             └────────────────────────┴───────────┬────────────┴────────────────────────┘
                                                  ▼
                                 API GATEWAY & SECURITY LAYER
                 ┌─────────────────────────────────────────────────────────────┐
                 │ • JWT Bearer Authentication & Multi-Tenant Role Isolation   │
                 │ • Rate Limiting, Request Logging, & CORS Management         │
                 │ • Class 3 Digital Signature Certificate (DSC) & Webhooks    │
                 └──────────────────────────────┬──────────────────────────────┘
                                                ▼
                               CORE BACKEND SERVICES (FastAPI Core)
  ┌───────────────────────┬────────────────────────┬────────────────────────┬───────────────────────┐
  │  INSPECTION ENGINE    │  RULE & OCR ENGINE     │  NOTICE GENERATOR      │  SUPPLY CHAIN GRAPH   │
  │  • Offline Sync Buffer│  • Groq LLaMA-3.3-70B  │  • Section 36/48/49    │  • Recursive Traceback│
  │  • Geolocation & Route│  • 23 Statutory Rules  │  • Automated PDF/DOCX  │  • Upstream Raid Auto-│
  │  • Evidence Storage   │  • 15 Mandatory Fields │  • eMudhra / DocuSign  │    creation on Match  │
  └───────────────────────┴───────────┬────────────┴────────────────────────┴───────────────────────┘
                                      ▼
                                 DATA PERSISTENCE
                 ┌─────────────────────────────────────────────────────────────┐
                 │ • PostgreSQL 16 (Primary ACID Store with Auto-SQLite Backup)│
                 │ • Local Encrypted Evidence Vault (PDFs, Images, Signatures) │
                 │ • Knowledge Base: Statutory Compounding & Penalty Matrices  │
                 └─────────────────────────────────────────────────────────────┘
```

---

## ✨ Core Features & Technical Highlights

### 1. Multi-Angle Computer Vision & Neural Statutory Parser
- Multi-angle capture of package labels (Front, Back, Side, Nutritional panel).
- Neural packaging parser extracts statutory declarations: MRP, Net Quantity, Date of Manufacture/Import, Consumer Care Contact, Manufacturer/Packer Address, Unit Sale Price (USP), Best Before/Expiry.
- Eliminates human bias in detecting missing or deceptive font-size violations under Rule 9 of LM (PC) Rules 2011.

### 2. Legal Metrology Compliance Rule Engine
- Evaluates extracted label data against the **23 statutory rules** and **15 mandatory declaration fields**.
- Distinguishes between first-time violations and repeat offences under Section 36 & Section 48 of the Legal Metrology Act, 2009.
- Automatic calculation of compounding fees based on statutory slabs.

### 3. Upstream Supply Chain Traceback & Auto-Case Generation
- When an inspector identifies a violation at a retail outlet, the inspector records the supplier/distributor declaration (Step 6 of the Inspection Wizard).
- If the supplier matches a registered business entity, the backend automatically generates an **Upstream Legal Case** and flags it for controller review and immediate raid deployment.

### 4. Automated Legal Notice Generation with DSC
- Generates official government notices (Show Cause Notices, Compounding Notices, and Final Penalty Orders) adhering to statutory formats.
- Previews real-time PDFs embedded with official departmental seals, QR codes, and digital signatures.

### 5. Multi-Tenant Role-Based Access Control (RBAC)
- Strict tenant segregation across 4 personas: `INSPECTOR`, `CONTROLLER`, `BUSINESS`, and `CITIZEN`.
- Cryptographic password hashing (PBKDF2 SHA-256) and JWT tokens with automatic session refresh.

---

## 👥 Stakeholder Personas & Credentials

| Role | Interface | Sample Login | Default Password | Capabilities |
| :--- | :--- | :--- | :--- | :--- |
| **Inspector** | Flutter Mobile | `sumit@gov.in` | `password123` | Conduct inspections, OCR scans, record violations, declare suppliers, view assigned cases. |
| **Central Controller**| Next.js Web | `controller@gov.in` | `password123` | Command radar, case assignment, deploy raids, approve compounding, issue DSC notices. |
| **Business Entity** | Flutter / Web | `reliance@retail.in` | `password123` | View received notices, run pre-market self checks, pay compounding penalties via UPI. |
| **Citizen Whistleblower**| Next.js Web | `citizen@gov.in` | `password123` | File geotagged packaging complaints, track bounty rewards, access National Helpline 1915. |

---

## 🚀 Quick Start & How to Run

> [!TIP]
> For a detailed presentation guide covering USB debugging, wireless hotspot APKs, and no-phone Windows desktop modes, please read [JURY_RUN_GUIDE.md](file:///e:/SIH_2026/Legal_Metrology/JURY_RUN_GUIDE.md).

### 1. Start the Database
The backend connects to PostgreSQL with an automatic zero-config SQLite fallback (`legal_metrology.db`).
```powershell
Start-Service postgresql-x64-16
```

### 2. Start the Backend API (FastAPI)
```powershell
cd e:\SIH_2026\Stay_Calm
python -m uvicorn backend.server:app --host 0.0.0.0 --port 8000 --reload
```
- API Base: `http://localhost:8000/api/v1`
- Swagger Documentation: `http://localhost:8000/docs`

### 3. Start the Web Portal (Next.js)
```powershell
cd e:\SIH_2026\Stay_Calm\sih-web
npm run dev
```
- Web Portal URL: `http://localhost:3000`

### 4. Start the Mobile App (Flutter)
Choose any of the three options:
- **Option A (Native Windows Desktop - No Phone Needed):**
  ```powershell
  cd e:\SIH_2026\Stay_Calm\mobile_app
  flutter run -d windows
  ```
- **Option B (Real Phone via USB):**
  ```powershell
  adb reverse tcp:8000 tcp:8000
  cd e:\SIH_2026\Stay_Calm\mobile_app
  flutter run
  ```
- **Option C (Real Phone Wirelessly via Hotspot):**
  ```powershell
  cd e:\SIH_2026\Stay_Calm\mobile_app
  flutter build apk --debug --dart-define=API_BASE_URL=http://<YOUR_HOTSPOT_IP>:8000/api/v1
  ```

---

## 📂 Project Structure

```
├── backend/                         # FastAPI Application Core
│   ├── server.py                    # REST API endpoints & route orchestration
│   ├── models.py                    # SQLAlchemy ORM database models
│   ├── database.py                  # Dual PostgreSQL / SQLite engine
│   ├── ocr_service.py               # Vision & Neural Statutory Parser (Groq LLaMA)
│   ├── rule_engine.py               # Legal Compliance Rule Engine
│   ├── notice_service.py            # PDF & DOCX Statutory Notice Generator
│   └── integrations.py              # Razorpay, eMudhra DSC, & Storage connectors
│
├── sih-web/                         # Next.js 16 Web Application
│   ├── src/app/                     # Next.js App Router (Controller & Citizen portals)
│   ├── src/components/              # Reusable UI components & GIS Leaflet maps
│   └── public/                      # Static assets & brand emblems
│
├── mobile_app/                      # Flutter Cross-Platform Application
│   ├── lib/core/                    # Auth, routing, network client (Dio), theme
│   ├── lib/features/inspector/      # 9-Step Inspection Wizard, OCR, Evidence Capture
│   ├── lib/features/business/       # Business self-checks, digital notices & payments
│   ├── lib/models/                  # Dart domain models & serializers
│   └── lib/di/providers.dart        # Riverpod dependency injection wiring
│
├── Knowledgebase/                   # Statutory Rulebooks & Compounding Matrices
│   ├── rulebook.json                # 23 statutory rules & 15 mandatory fields
│   ├── compounding_matrix.json      # Penalty computation tables (1st vs 2nd offence)
│   └── legal_sources.json           # Citations for Legal Metrology Act, 2009
│
├── Notices_Template/generated/      # Generated legal PDF notices
├── TEST_UPLOADS/                    # Geotagged evidence photos & digital signatures
├── JURY_RUN_GUIDE.md                # Complete live jury demonstration handbook
└── README.md                        # Master repository documentation
```

---

## 📜 Statutory Framework & Legal Acts Enforced

| Act / Rule | Sections / Rules Enforced | Digital Enforcement Implementation |
| :--- | :--- | :--- |
| **Legal Metrology Act, 2009** | Section 15 | Digital Panchanama & seizure orders with GPS timestamps |
| **Legal Metrology Act, 2009** | Section 36 | Penalties for non-standard packaging; auto-fine computation |
| **Legal Metrology Act, 2009** | Section 48 | Compounding of offences with online payment gateway |
| **Legal Metrology Act, 2009** | Section 49 | Corporate liability; auto-linking of directors & packers |
| **LM (Packaged Commodities) Rules, 2011** | Rule 6 | Mandatory declarations: MRP, Net Qty, Dates, Address, USP |
| **LM (Packaged Commodities) Rules, 2011** | Rule 9 | Declaration font height-to-area ratio verified via OCR |

---

## 🏆 SIH 2026 Innovation Highlights

1. **Zero-Paper Enforcement:** Inspection to prosecution notice flow completed in under 90 seconds.
2. **Upstream Supply Chain Accountability:** Eliminates the retail scapegoat problem by automatically issuing compounding notices upstream to registered manufacturers and packers.
3. **Resilient Local Architecture:** Instant failover to local SQLite and offline sync buffer if connectivity fails in rural marketplaces.
4. **Transparent Governance:** Complete audit trail log for every notice, digital signature, and compounding transaction.
