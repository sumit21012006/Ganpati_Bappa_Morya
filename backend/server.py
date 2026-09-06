import os
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel

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

# In-Memory shared database for demo
DB = {
    "complaints": [],
    "cases": {},
    "notices": [],
    "inspections": []
}

class ExtractPackagingRequest(BaseModel):
    raw_text: Optional[str] = None
    previous_offences_count: int = 0
    product_category: str = "general_packaged_commodity"

class GenerateNoticeRequest(BaseModel):
    notice_type: str  # "compounding_order" | "improvement_notice" | "panchanama"
    case_id: str
    firm_name: str
    firm_address: str
    product_name: str
    violations: List[Dict[str, Any]] = []
    compounding_amount: Optional[str] = "25,000"
    person_name: Optional[str] = "Proprietor"
    ordering_officer_name: Optional[str] = "Dr. S. K. Deshmukh"

@app.get("/")
def health_check():
    return {
        "status": "ONLINE",
        "service": "Legal Metrology Core Enforcement Engine",
        "jurisdiction": "Maharashtra / Central Government of India",
        "version": "1.0.0"
    }

# ==============================================================================
# 1. MULTI-ANGLE OCR & COMPLIANCE VERIFICATION
# ==============================================================================

@app.post("/api/v1/ocr/extract-packaging")
async def extract_packaging_info(req: ExtractPackagingRequest):
    """
    Extracts the 9 statutory fields and executes compliance check against rulebook.json
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

# ==============================================================================
# 2. AUTOMATIC NOTICE & ORDER GENERATION (FROM TEMPLATES)
# ==============================================================================

@app.post("/api/v1/notices/generate")
async def generate_notice(req: GenerateNoticeRequest):
    """
    Generates authentic government documents directly from official docx templates.
    """
    data = req.model_dump()
    data["amount_in_words"] = "Twenty Five Thousand"
    
    if req.notice_type == "compounding_order":
        file_path = notice_gen.generate_compounding_order(data)
    elif req.notice_type == "improvement_notice":
        file_path = notice_gen.generate_improvement_notice(data)
    elif req.notice_type == "panchanama":
        file_path = notice_gen.generate_panchanama(data)
    else:
        raise HTTPException(status_code=400, detail="Invalid notice type")

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
# 3. DIGITAL SIGNATURES & PAYMENTS
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
# 4. CONTROLLER & SUPPLY CHAIN ENDPOINTS
# ==============================================================================

@app.get("/api/v1/controller/dashboard/stats")
async def get_controller_stats():
    return {
        "totalInspections": 14892,
        "firstOffencesLogged": 2410,
        "secondOffencesLogged": 342,
        "penaltiesRecoveredRupees": "8.42 Cr",
        "citizenRewardsPaidPoints": 842000,
        "activeOfficersCount": 1428
    }

@app.get("/api/v1/supply-chain/trace/{gstin}")
async def trace_supply_chain(gstin: str):
    return supply_chain_service.trace_upstream(gstin)
