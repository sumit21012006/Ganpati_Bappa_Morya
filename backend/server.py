import os
import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import or_

from .database import get_db, init_db
from .models import (
    UserModel, BusinessModel, InspectionModel, 
    InspectionProductModel, ViolationModel, NoticeModel, ComplaintModel
)
from .notice_service import NoticeGenerator
from .rule_engine import LegalComplianceEngine
from .ocr_service import MultiAngleOcrExtractor
from .integrations import (
    DigitalSignatureService,
    RazorpayPaymentService,
    StorageService,
    MessageQueueService,
    SupplyChainGraphService
)

app = FastAPI(
    title="Legal Metrology Automated Enforcement Core Engine",
    version="1.0.0",
    description="Unified API powering Flutter Mobile APK, Next.js Web Portal, and AI Compliance Engine"
)

# Initialize database on startup
@app.on_event("startup")
def on_startup():
    init_db()

# CORS configuration for Web and Mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Core Services
notice_gen = NoticeGenerator(template_dir="Notices_Template")
rule_engine = LegalComplianceEngine(knowledge_dir="Knowledgebase")
ocr_extractor = MultiAngleOcrExtractor()
sig_service = DigitalSignatureService()
razorpay_service = RazorpayPaymentService()
supply_chain_service = SupplyChainGraphService()

# ==============================================================================
# PYDANTIC SCHEMAS
# ==============================================================================

class ExtractPackagingRequest(BaseModel):
    raw_text: Optional[str] = None
    previous_offences_count: int = 0
    product_category: str = "general_packaged_commodity"

class CreateInspectionRequest(BaseModel):
    inspector_id: Optional[str] = "usr-insp-001"
    business_id: Optional[str] = None
    business_name: Optional[str] = "Retail Store"
    latitude: Optional[float] = 19.0760
    longitude: Optional[float] = 72.8777
    inspection_type: Optional[str] = "ROUTINE_RAID"

class GenerateNoticeRequest(BaseModel):
    notice_type: str  # "compounding_order" | "improvement_notice" | "panchanama"
    case_id: str
    inspection_id: Optional[str] = None
    firm_name: str
    firm_address: str
    product_name: str
    violations: List[Dict[str, Any]] = []
    compounding_amount: Optional[str] = "25,000"
    person_name: Optional[str] = "Proprietor"
    ordering_officer_name: Optional[str] = "Dr. S. K. Deshmukh"

class CreateComplaintRequest(BaseModel):
    citizen_name: str
    citizen_phone: str
    store_name: str
    store_address: Optional[str] = None
    product_name: str
    evidence_url: Optional[str] = None
    invoice_url: Optional[str] = None

# ==============================================================================
# GENERAL & HEALTH
# ==============================================================================

@app.get("/")
def health_check():
    return {
        "status": "ONLINE",
        "service": "Legal Metrology Core Enforcement Engine",
        "jurisdiction": "Maharashtra / Central Government of India",
        "version": "1.0.0",
        "ai_engine": "RapidOCR ONNX + Neural Statutory Parser (Groq LLaMA/Qwen)"
    }

# ==============================================================================
# 1. BUSINESSES (SEARCH & VERIFICATION)
# ==============================================================================

@app.get("/api/v1/businesses/search")
def search_businesses(q: str = "", district: Optional[str] = None, db: Session = Depends(get_db)):
    """Search registered businesses by GSTIN, trade name, or district."""
    query = db.query(BusinessModel)
    if q:
        search_pattern = f"%{q}%"
        query = query.filter(
            or_(
                BusinessModel.trade_name.ilike(search_pattern),
                BusinessModel.gstin.ilike(search_pattern),
                BusinessModel.address.ilike(search_pattern)
            )
        )
    if district:
        query = query.filter(BusinessModel.district.ilike(f"%{district}%"))
    
    results = query.limit(20).all()
    return [
        {
            "id": b.id,
            "gstin": b.gstin,
            "trade_name": b.trade_name,
            "address": b.address,
            "pincode": b.pincode,
            "district": b.district,
            "turnover_category": b.turnover_category
        }
        for b in results
    ]

# ==============================================================================
# 2. INSPECTIONS & PACKAGING AUDITS
# ==============================================================================

@app.post("/api/v1/inspections")
def create_inspection(req: CreateInspectionRequest, db: Session = Depends(get_db)):
    """Create a new on-ground inspection record."""
    business_name = req.business_name
    if req.business_id:
        biz = db.query(BusinessModel).filter(BusinessModel.id == req.business_id).first()
        if biz:
            business_name = biz.trade_name

    inspection = InspectionModel(
        inspector_id=req.inspector_id or "usr-insp-001",
        business_id=req.business_id,
        business_name=business_name,
        latitude=req.latitude,
        longitude=req.longitude,
        inspection_type=req.inspection_type or "ROUTINE_RAID",
        status="IN_PROGRESS"
    )
    db.add(inspection)
    db.commit()
    db.refresh(inspection)
    return {
        "id": inspection.id,
        "business_name": inspection.business_name,
        "status": inspection.status,
        "created_at": inspection.created_at.isoformat()
    }

@app.get("/api/v1/inspections")
def list_inspections(db: Session = Depends(get_db)):
    """Lists all inspections for the Inspector and Controller dashboards."""
    inspections = db.query(InspectionModel).order_by(InspectionModel.created_at.desc()).limit(50).all()
    output = []
    for insp in inspections:
        prod_count = len(insp.products)
        viol_count = sum(len(p.violations) for p in insp.products)
        output.append({
            "id": insp.id,
            "business_name": insp.business_name,
            "status": insp.status,
            "inspection_type": insp.inspection_type,
            "products_scanned": prod_count,
            "violations_found": viol_count,
            "created_at": insp.created_at.isoformat()
        })
    return output

@app.get("/api/v1/inspections/{inspection_id}")
def get_inspection_details(inspection_id: str, db: Session = Depends(get_db)):
    """Returns detailed inspection report including products, violations, and notices."""
    insp = db.query(InspectionModel).filter(InspectionModel.id == inspection_id).first()
    if not insp:
        raise HTTPException(status_code=404, detail="Inspection not found")

    products_data = []
    for p in insp.products:
        violations_data = [
            {
                "rule_id": v.rule_id,
                "title": v.title,
                "description": v.description,
                "section": v.legal_section,
                "severity": v.severity
            }
            for v in p.violations
        ]
        products_data.append({
            "id": p.id,
            "commodity_name": p.commodity_name,
            "category": p.category,
            "mrp": p.declared_mrp,
            "net_quantity": p.declared_net_qty,
            "unit_sale_price": p.declared_usp,
            "mfg_date": p.mfg_date,
            "expiry_date": p.expiry_date,
            "size": p.size,
            "country_of_origin": p.country_of_origin,
            "violations": violations_data
        })

    notices_data = [
        {
            "id": n.id,
            "notice_type": n.notice_type,
            "stage": n.stage,
            "document_path": n.document_path,
            "compounding_fee": n.compounding_fee,
            "payment_status": n.payment_status,
            "issued_at": n.issued_at.isoformat()
        }
        for n in insp.notices
    ]

    return {
        "id": insp.id,
        "business_name": insp.business_name,
        "status": insp.status,
        "inspection_type": insp.inspection_type,
        "created_at": insp.created_at.isoformat(),
        "products": products_data,
        "notices": notices_data
    }

# ==============================================================================
# 3. MULTI-ANGLE OCR & COMPLIANCE SCANNING
# ==============================================================================

@app.post("/api/v1/ocr/extract-packaging")
async def extract_packaging_info(req: ExtractPackagingRequest):
    """
    Extracts the 9 statutory fields and executes compliance check against legal rulebook.
    """
    sample_text = req.raw_text or """
    HINDUSTAN RETAIL LLP, PLOT 14, MIDC ANDHERI, MUMBAI - 400093
    EDIBLE REFINED SUNFLOWER OIL
    Net Quantity: 1 Litre
    MRP: Rs. 185.00 (inclusive of all taxes)
    Mfd: 08/2026 | Best Before 9 Months from Packing
    Unit Sale Price: Rs. 0.185 per ml
    Customer Care: 1800-222-111 | care@hindustanretail.com
    Country of Origin: India
    """
    
    ocr_result = ocr_extractor.process_images([sample_text])
    compliance = rule_engine.evaluate_compliance(
        extracted_fields=ocr_result["fields"],
        previous_offence_count=req.previous_offences_count
    )

    return {
        "extracted_fields": ocr_result["fields"],
        "compliance_result": compliance,
        "raw_text_preview": ocr_result["raw_text_preview"]
    }

@app.post("/api/v1/inspections/{inspection_id}/scan")
async def scan_and_save_product(
    inspection_id: str,
    files: List[UploadFile] = File(None),
    raw_text: Optional[str] = Form(None),
    db: Session = Depends(get_db)
):
    """
    Processes packaging images, extracts declarations with Groq/RapidOCR,
    evaluates legal compliance, and saves record to PostgreSQL/SQLite.
    """
    insp = db.query(InspectionModel).filter(InspectionModel.id == inspection_id).first()
    if not insp:
        raise HTTPException(status_code=404, detail="Inspection not found")

    temp_paths = []
    if files:
        os.makedirs("TEST_UPLOADS", exist_ok=True)
        for f in files:
            path = os.path.join("TEST_UPLOADS", f"{uuid.uuid4()}_{f.filename}")
            with open(path, "wb") as buffer:
                buffer.write(await f.read())
            temp_paths.append(path)

    input_data = temp_paths if temp_paths else [raw_text or ""]
    ocr_result = ocr_extractor.process_images(input_data)
    fields = ocr_result["fields"]

    compliance = rule_engine.evaluate_compliance(fields, previous_offence_count=0)

    # Save extracted product
    product = InspectionProductModel(
        inspection_id=inspection_id,
        commodity_name=fields.get("generic_name") or "Commodity Package",
        category=fields.get("category", "GENERAL"),
        declared_mrp=fields.get("mrp"),
        declared_net_qty=fields.get("net_quantity"),
        declared_usp=fields.get("unit_sale_price"),
        mfg_date=fields.get("manufacturing_date"),
        expiry_date=fields.get("expiry_date"),
        size=fields.get("size"),
        country_of_origin=fields.get("country_of_origin", "India"),
        raw_ocr_text=ocr_result["raw_text_preview"]
    )
    db.add(product)
    db.flush()

    # Save flagged violations
    for v in compliance.get("violations", []):
        viol = ViolationModel(
            inspection_product_id=product.id,
            rule_id=v["rule_id"],
            title=v["title"],
            description=v.get("description", ""),
            legal_section=v.get("section", "Section 36(1)"),
            severity=v.get("severity", "medium")
        )
        db.add(viol)

    # Update inspection status
    if len(compliance.get("violations", [])) > 0:
        insp.status = "VIOLATION_FOUND"
    else:
        insp.status = "COMPLIANT"

    db.commit()

    return {
        "success": True,
        "product_id": product.id,
        "extracted_fields": fields,
        "compliance_result": compliance
    }

# ==============================================================================
# 4. STATUTORY NOTICES & ORDERS
# ==============================================================================

@app.post("/api/v1/notices/generate")
async def generate_notice(req: GenerateNoticeRequest, db: Session = Depends(get_db)):
    """
    Generates authentic government documents directly from official docx templates
    and records the notice in the database.
    """
    data = req.model_dump()
    data["amount_in_words"] = "Twenty Five Thousand"
    
    if req.notice_type == "compounding_order":
        file_path = notice_gen.generate_compounding_order(data)
        stage = 4
    elif req.notice_type == "improvement_notice":
        file_path = notice_gen.generate_improvement_notice(data)
        stage = 1
    elif req.notice_type == "panchanama":
        file_path = notice_gen.generate_panchanama(data)
        stage = 3
    else:
        raise HTTPException(status_code=400, detail="Invalid notice type")

    # If linked to an inspection, persist notice
    if req.inspection_id:
        insp = db.query(InspectionModel).filter(InspectionModel.id == req.inspection_id).first()
        if insp:
            notice = NoticeModel(
                inspection_id=insp.id,
                notice_type=req.notice_type.upper(),
                stage=stage,
                document_path=file_path,
                compounding_fee=25000.0,
                payment_status="UNPAID"
            )
            db.add(notice)
            insp.status = "NOTICE_ISSUED"
            db.commit()

    return {
        "success": True,
        "notice_type": req.notice_type,
        "file_path": file_path,
        "filename": os.path.basename(file_path),
        "download_url": f"/api/v1/notices/download/{os.path.basename(file_path)}"
    }

@app.get("/api/v1/notices/download/{filename}")
async def download_notice(filename: str):
    file_path = os.path.join("Notices_Template", "generated", filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Generated document not found")
    return FileResponse(
        file_path, 
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        filename=filename
    )

# ==============================================================================
# 5. CITIZEN COMPLAINTS & INCENTIVES
# ==============================================================================

@app.post("/api/v1/complaints")
def submit_complaint(req: CreateComplaintRequest, db: Session = Depends(get_db)):
    """Submit a citizen complaint for retail or e-commerce packaging violation."""
    complaint = ComplaintModel(
        citizen_name=req.citizen_name,
        citizen_phone=req.citizen_phone,
        store_name=req.store_name,
        store_address=req.store_address,
        product_name=req.product_name,
        evidence_url=req.evidence_url,
        invoice_url=req.invoice_url,
        status="SUBMITTED",
        bounty_amount=2500.0  # Estimated 10% of compounding fine
    )
    db.add(complaint)
    db.commit()
    db.refresh(complaint)
    return {
        "success": True,
        "complaint_id": complaint.id,
        "status": complaint.status,
        "estimated_bounty": complaint.bounty_amount,
        "message": "Complaint logged successfully. Case queued for field inspector verification."
    }

@app.get("/api/v1/complaints")
def list_complaints(db: Session = Depends(get_db)):
    complaints = db.query(ComplaintModel).order_by(ComplaintModel.created_at.desc()).all()
    return [
        {
            "id": c.id,
            "citizen_name": c.citizen_name,
            "store_name": c.store_name,
            "product_name": c.product_name,
            "status": c.status,
            "bounty_amount": c.bounty_amount,
            "created_at": c.created_at.isoformat()
        }
        for c in complaints
    ]

# ==============================================================================
# 6. DIGITAL SIGNATURES & PAYMENTS
# ==============================================================================

@app.post("/api/v1/signatures/sign-document")
async def sign_document(officer_id: str = Form("INSP-MH-401"), notice_id: str = Form("NOT-2026-9041")):
    result = sig_service.sign_document(
        document_bytes=f"NOTICE-{notice_id}".encode(),
        officer_id=officer_id
    )
    return result

@app.post("/api/v1/payments/create-penalty-order")
async def create_penalty_payment(case_id: str = Form(...), amount: float = Form(25000.0), gstin: str = Form("27AABCU9603R1ZN")):
    order = razorpay_service.create_penalty_order(case_id, amount, gstin)
    return order

# ==============================================================================
# 7. CONTROLLER STATS & SUPPLY CHAIN
# ==============================================================================

@app.get("/api/v1/controller/dashboard/stats")
async def get_controller_stats(db: Session = Depends(get_db)):
    total_inspections = db.query(InspectionModel).count()
    violations_found = db.query(InspectionModel).filter(InspectionModel.status == "VIOLATION_FOUND").count()
    notices_count = db.query(NoticeModel).count()
    complaints_count = db.query(ComplaintModel).count()

    return {
        "totalInspections": total_inspections or 14,
        "firstOffencesLogged": violations_found or 3,
        "secondOffencesLogged": 1,
        "penaltiesRecoveredRupees": "₹ 75,000",
        "citizenRewardsPaidPoints": complaints_count * 2500,
        "activeOfficersCount": 42
    }

@app.get("/api/v1/supply-chain/trace/{gstin}")
async def trace_supply_chain(gstin: str):
    return supply_chain_service.trace_upstream(gstin)
