import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy import (
    Column, String, Text, Float, Integer, Boolean, DateTime, ForeignKey, JSON
)
from sqlalchemy.orm import relationship
from .database import Base

def generate_uuid():
    return str(uuid.uuid4())

class UserModel(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # CITIZEN, BUSINESS, INSPECTOR, CONTROLLER
    phone = Column(String(20), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=True)
    district = Column(String(100), default="Mumbai")
    created_at = Column(DateTime, default=datetime.utcnow)

    businesses = relationship("BusinessModel", back_populates="owner")
    inspections = relationship("InspectionModel", back_populates="inspector")
    complaints = relationship("ComplaintModel", back_populates="citizen")

class BusinessModel(Base):
    __tablename__ = "businesses"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    gstin = Column(String(15), unique=True, index=True, nullable=True)
    trade_name = Column(String(255), nullable=False, index=True)
    address = Column(Text, nullable=False)
    pincode = Column(String(10), default="400001")
    district = Column(String(100), default="Mumbai", index=True)
    turnover_category = Column(String(50), default="MICRO")  # MICRO, SMALL, MEDIUM, LARGE
    owner_user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("UserModel", back_populates="businesses")
    inspections = relationship("InspectionModel", back_populates="business")

class InspectionModel(Base):
    __tablename__ = "inspections"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    inspector_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    business_id = Column(String(36), ForeignKey("businesses.id"), nullable=True)
    business_name = Column(String(255), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    inspection_type = Column(String(50), default="ROUTINE_RAID")  # ROUTINE_RAID, CITIZEN_COMPLAINT, SUPPLY_CHAIN_LEAD
    status = Column(String(50), default="IN_PROGRESS")  # IN_PROGRESS, COMPLIANT, VIOLATION_FOUND, NOTICE_ISSUED, COMPOUNDED
    created_at = Column(DateTime, default=datetime.utcnow)

    inspector = relationship("UserModel", back_populates="inspections")
    business = relationship("BusinessModel", back_populates="inspections")
    products = relationship("InspectionProductModel", back_populates="inspection", cascade="all, delete-orphan")
    notices = relationship("NoticeModel", back_populates="inspection", cascade="all, delete-orphan")

class InspectionProductModel(Base):
    __tablename__ = "inspection_products"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    inspection_id = Column(String(36), ForeignKey("inspections.id"), nullable=False)
    commodity_name = Column(String(255), nullable=True)
    category = Column(String(100), default="GENERAL")
    brand_name = Column(String(255), nullable=True)
    declared_mrp = Column(String(100), nullable=True)
    declared_net_qty = Column(String(100), nullable=True)
    declared_usp = Column(String(100), nullable=True)
    mfg_date = Column(String(100), nullable=True)
    expiry_date = Column(String(100), nullable=True)
    size = Column(String(100), nullable=True)
    country_of_origin = Column(String(100), default="India")
    raw_ocr_text = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    inspection = relationship("InspectionModel", back_populates="products")
    violations = relationship("ViolationModel", back_populates="product", cascade="all, delete-orphan")

class ViolationModel(Base):
    __tablename__ = "violations"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    inspection_product_id = Column(String(36), ForeignKey("inspection_products.id"), nullable=False)
    rule_id = Column(String(50), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    legal_section = Column(String(100), nullable=False)
    severity = Column(String(50), default="medium")  # low, medium, high, critical
    is_second_offence = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    product = relationship("InspectionProductModel", back_populates="violations")

class NoticeModel(Base):
    __tablename__ = "notices"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    inspection_id = Column(String(36), ForeignKey("inspections.id"), nullable=False)
    notice_type = Column(String(50), nullable=False)  # IMPROVEMENT_NOTICE, SEIZURE_LIST, PANCHANAMA, COMPOUNDING_ORDER
    stage = Column(Integer, default=1)
    document_path = Column(String(500), nullable=False)
    digital_signature_hash = Column(Text, nullable=True)
    compounding_fee = Column(Float, default=25000.0)
    payment_status = Column(String(50), default="UNPAID")  # UNPAID, PAID, EXEMPTED
    issued_at = Column(DateTime, default=datetime.utcnow)

    inspection = relationship("InspectionModel", back_populates="notices")

class ComplaintModel(Base):
    __tablename__ = "complaints"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    citizen_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    citizen_name = Column(String(255), default="Aware Citizen")
    citizen_phone = Column(String(20), default="9876543210")
    store_name = Column(String(255), nullable=False)
    store_address = Column(Text, nullable=True)
    product_name = Column(String(255), nullable=False)
    evidence_url = Column(String(500), nullable=True)
    invoice_url = Column(String(500), nullable=True)
    status = Column(String(50), default="SUBMITTED")  # SUBMITTED, VERIFIED, RAIDED, COMPOUNDED, REJECTED
    bounty_amount = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)

    citizen = relationship("UserModel", back_populates="complaints")


def seed_initial_data(db):
    """Seeds realistic demonstration businesses and officers."""
    if db.query(BusinessModel).count() > 0:
        return

    # Seed Inspector & Controller Users
    inspector_user = UserModel(
        id="usr-insp-001",
        name="Inspector Rajesh Shinde",
        role="INSPECTOR",
        phone="9820011223",
        email="rajesh.shinde@mahalm.gov.in",
        district="Mumbai Suburban"
    )
    controller_user = UserModel(
        id="usr-ctrl-001",
        name="Dr. S. K. Deshmukh (Controller)",
        role="CONTROLLER",
        phone="9820099887",
        email="controller@mahalm.gov.in",
        district="State Headquarters, Mumbai"
    )
    citizen_user = UserModel(
        id="usr-citz-001",
        name="Sumit Patil (Citizen)",
        role="CITIZEN",
        phone="9890123456",
        email="sumit.patil@gmail.com",
        district="Pune"
    )
    db.add_all([inspector_user, controller_user, citizen_user])
    db.commit()

    # Seed Demonstration Businesses (SHGs, FMCG, Durables, Footwear)
    businesses = [
        BusinessModel(
            id="biz-001",
            gstin="27AAACS1234F1Z5",
            trade_name="Suman Mahila Gruh Udhyog",
            address="Plot 4, Adajan, Surat, Gujarat - 395005",
            pincode="395005",
            district="Surat",
            turnover_category="MICRO"
        ),
        BusinessModel(
            id="biz-002",
            gstin="27AABCA5678B1Z2",
            trade_name="Artisan Foods Pvt Ltd",
            address="Survey No. 45/2, Village Kelva, Off NH-48, Palghar, Thane - 401401",
            pincode="401401",
            district="Palghar",
            turnover_category="SMALL"
        ),
        BusinessModel(
            id="biz-003",
            gstin="27AABCK9012C1Z8",
            trade_name="K.I. Glassware India Pvt Ltd",
            address="17A/41, Gurudwara Road, Karol Bagh, New Delhi - 110005",
            pincode="110005",
            district="Central Delhi",
            turnover_category="MEDIUM"
        ),
        BusinessModel(
            id="biz-004",
            gstin="29AABCR3456D1Z1",
            trade_name="Robemall Apparels Pvt Ltd (Zovi)",
            address="Krishna Mansion, JP Nagar 1st Phase, Bangalore - 560078",
            pincode="560078",
            district="Bangalore",
            turnover_category="LARGE"
        ),
        BusinessModel(
            id="biz-005",
            gstin="27AABCU7890E1Z9",
            trade_name="Uday Gruh Udhyog",
            address="Gala No. 12, Industrial Area, Thane West - 400601",
            pincode="400601",
            district="Thane",
            turnover_category="MICRO"
        )
    ]
    db.add_all(businesses)
    db.commit()
    print("[INFO] Initial demonstration users and businesses seeded into database.")
