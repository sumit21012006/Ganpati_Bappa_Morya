/// Realistic Indian mock dataset for DEMO mode. Only the mock repositories
/// and the demo overlay read this file — UI and real repositories never do.
library;

import '../models/business.dart';
import '../models/inspection.dart';
import '../models/notice.dart';
import '../models/offence_history.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/self_check.dart';
import '../models/user.dart';
import '../models/violation.dart';

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

final demoInspector = User(
  id: 'usr-inspector-001',
  name: 'Rajesh Deshmukh',
  role: UserRole.inspector,
  email: 'rajesh.deshmukh@legalmetrology.gov.in',
  phone: '+91 98220 11223',
  designation: 'Legal Metrology Officer, Grade I',
  badgeId: 'LMO-MH-2019-4471',
  jurisdiction: 'Pune Zone 3, Maharashtra',
);

final demoBusinessUser = User(
  id: 'usr-business-001',
  name: 'Anita Kulkarni',
  role: UserRole.business,
  email: 'anita@abctraders.in',
  phone: '+91 99700 45678',
  businessId: 'biz-001',
);

// ---------------------------------------------------------------------------
// Businesses
// ---------------------------------------------------------------------------

final mockBusinesses = <Business>[
  const Business(
    id: 'biz-001',
    name: 'ABC Traders',
    type: BusinessType.retailer,
    status: BusinessStatus.active,
    location: BusinessLocation(
      addressLine: 'Shop 14, Laxmi Road Market',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411002',
    ),
    gstin: '27AABCU9603R1ZM',
    ownerName: 'Anita Kulkarni',
    contactPhone: '+91 99700 45678',
    annualTurnover: 8500000,
  ),
  const Business(
    id: 'biz-002',
    name: 'Maharashtra Home Foods',
    type: BusinessType.packer,
    status: BusinessStatus.active,
    location: BusinessLocation(
      addressLine: 'Plot 42, MIDC Bhosari Industrial Area',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411026',
    ),
    gstin: '27AAFCM1234K1Z9',
    ownerName: 'Suresh Patil',
    contactPhone: '+91 98230 76543',
    annualTurnover: 42000000,
  ),
  const Business(
    id: 'biz-003',
    name: 'XYZ Retail',
    type: BusinessType.retailer,
    status: BusinessStatus.active,
    location: BusinessLocation(
      addressLine: 'Unit 7, Phoenix Marketcity, Nagar Road',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411014',
    ),
    gstin: '27AAGCX7789M1Z4',
    ownerName: 'Farhan Shaikh',
    contactPhone: '+91 90040 22110',
    annualTurnover: 120000000,
  ),
  const Business(
    id: 'biz-004',
    name: 'Sai Provisions',
    type: BusinessType.wholesaler,
    status: BusinessStatus.pending,
    location: BusinessLocation(
      addressLine: 'Warehouse 3, Market Yard, Gultekdi',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411037',
    ),
    gstin: '27AADCS4455P1ZQ',
    ownerName: 'Vikram Jadhav',
    contactPhone: '+91 97650 33445',
    annualTurnover: 15000000,
  ),
  const Business(
    id: 'biz-005',
    name: 'Ganesh Kirana Stores',
    type: BusinessType.retailer,
    status: BusinessStatus.active,
    location: BusinessLocation(
      addressLine: '12/3 Karve Road, Kothrud',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411038',
    ),
    gstin: '27AAECG9012L1ZP',
    ownerName: 'Meena Joshi',
    contactPhone: '+91 88880 11220',
    annualTurnover: 4200000,
  ),
];

// ---------------------------------------------------------------------------
// Products
// ---------------------------------------------------------------------------

const mockProducts = <Product>[
  Product(
    id: 'prd-001',
    name: 'Surf Excel Easy Wash Detergent Powder 1 kg',
    brand: 'Surf Excel',
    category: 'Household — Detergent',
    manufacturer: 'Hindustan Unilever Ltd',
    packSize: '1 kg',
  ),
  Product(
    id: 'prd-002',
    name: 'Aashirvaad Whole Wheat Atta 5 kg',
    brand: 'Aashirvaad',
    category: 'Packaged Food — Staples',
    manufacturer: 'ITC Ltd',
    packSize: '5 kg',
  ),
  Product(
    id: 'prd-003',
    name: 'Tata Salt Iodised 1 kg',
    brand: 'Tata',
    category: 'Packaged Food — Staples',
    manufacturer: 'Tata Consumer Products Ltd',
    packSize: '1 kg',
  ),
  Product(
    id: 'prd-004',
    name: 'Amul Gold Homogenised Standardised Milk 500 ml',
    brand: 'Amul',
    category: 'Packaged Food — Dairy',
    manufacturer: 'Amul (GCMMF)',
    packSize: '500 ml',
  ),
  Product(
    id: 'prd-005',
    name: 'Harpic Power Plus Toilet Cleaner 1 L',
    brand: 'Harpic',
    category: 'Household — Cleaner',
    manufacturer: 'Reckitt Benckiser India Pvt Ltd',
    packSize: '1 L',
  ),
];

// ---------------------------------------------------------------------------
// Violations (AI potential findings used in the demo inspection flow)
// ---------------------------------------------------------------------------

Violation mockAiViolation1() => Violation(
      id: 'vio-001',
      type: ViolationType.incorrectMrp,
      description:
          'Declared MRP ₹115.00 does not match the printed inclusive-of-taxes '
          'computation for the pack size; MRP appears tampered over the '
          'original print.',
      severity: ViolationSeverity.high,
      status: ViolationStatus.potential,
      ruleSection: 'Rule 2(m), Legal Metrology (Packaged Commodities) Rules, 2011',
      ruleTitle: 'Declaration of MRP on pre-packaged commodities',
      confidence: 0.91,
      recommendation:
          'Verify the dual MRP printing with the manufacturer; dual/tampered '
          'MRP declarations are prohibited on retail packages.',
      sourceImageId: 'evd-front',
      isAiGenerated: true,
      detectedAt: DateTime(2026, 8, 21, 11, 42),
    );

Violation mockAiViolation2() => Violation(
      id: 'vio-002',
      type: ViolationType.consumerCareIssue,
      description:
          'Consumer-care declaration is present but missing the required '
          'e-mail address as per the prescribed format.',
      severity: ViolationSeverity.medium,
      status: ViolationStatus.potential,
      ruleSection: 'Rule 6(3), Legal Metrology (Packaged Commodities) Rules, 2011',
      ruleTitle: 'Name and particulars of consumer-care cell',
      confidence: 0.78,
      recommendation:
          'Consumer-care particulars must include phone number AND e-mail '
          'address. Ask the business to correct on next print run.',
      sourceImageId: 'evd-back',
      isAiGenerated: true,
      detectedAt: DateTime(2026, 8, 21, 11, 42),
    );

Violation mockAiViolation3() => Violation(
      id: 'vio-003',
      type: ViolationType.netQuantityIssue,
      description:
          'Net quantity printed as "1 KG" using non-standard symbol; must '
          'use prescribed units ("1 kg" with standard numeral font height).',
      severity: ViolationSeverity.low,
      status: ViolationStatus.potential,
      ruleSection: 'Rule 7, Legal Metrology (Packaged Commodities) Rules, 2011',
      ruleTitle: 'Declaration of quantity — standard units and symbols',
      confidence: 0.66,
      recommendation:
          'Rectify the unit symbol to the prescribed SI form on the next '
          'labelling revision.',
      sourceImageId: 'evd-side',
      isAiGenerated: true,
      detectedAt: DateTime(2026, 8, 21, 11, 42),
    );

// ---------------------------------------------------------------------------
// Inspections
// ---------------------------------------------------------------------------

final mockInspections = <Inspection>[
  Inspection(
    id: 'INSP-2026-00042',
    business: mockBusinesses[1], // Maharashtra Home Foods
    type: InspectionType.complaintBased,
    status: InspectionStatus.assigned,
    scheduledAt: DateTime(2026, 9, 6, 10, 30),
    createdAt: DateTime(2026, 9, 4, 9, 15),
    inspectorId: demoInspector.id,
    inspectorName: demoInspector.name,
    complaintId: 'CMP/2026/0891',
    products: [mockProducts[1], mockProducts[2]],
  ),
  Inspection(
    id: 'INSP-2026-00039',
    business: mockBusinesses[2], // XYZ Retail
    type: InspectionType.routine,
    status: InspectionStatus.assigned,
    scheduledAt: DateTime(2026, 9, 6, 15, 0),
    createdAt: DateTime(2026, 9, 3, 14, 0),
    inspectorId: demoInspector.id,
    inspectorName: demoInspector.name,
    products: [mockProducts[0], mockProducts[4]],
  ),
  Inspection(
    id: 'INSP-2026-00035',
    business: mockBusinesses[4], // Ganesh Kirana Stores
    type: InspectionType.supplyChainLinked,
    status: InspectionStatus.noticeIssued,
    scheduledAt: DateTime(2026, 9, 2, 11, 0),
    createdAt: DateTime(2026, 8, 30, 10, 0),
    inspectorId: demoInspector.id,
    inspectorName: demoInspector.name,
    products: [mockProducts[1]],
  ),
  Inspection(
    id: 'INSP-2026-00031',
    business: mockBusinesses[0], // ABC Traders
    type: InspectionType.routine,
    status: InspectionStatus.completed,
    scheduledAt: DateTime(2026, 8, 21, 11, 0),
    createdAt: DateTime(2026, 8, 19, 9, 0),
    inspectorId: demoInspector.id,
    inspectorName: demoInspector.name,
    products: [mockProducts[0]],
    completedAt: DateTime(2026, 8, 28, 17, 30),
  ),
];

// ---------------------------------------------------------------------------
// Cases
// ---------------------------------------------------------------------------

LegalCase _case1() => LegalCase(
      id: 'LM/2026/0187',
      productName: mockProducts[1].name,
      status: CaseStatus.noticeIssued,
      openedAt: DateTime(2026, 9, 2),
      counterpartyName: 'Ganesh Kirana Stores',
      role: UserRole.inspector,
      violationSummary:
          'Consumer-care declaration incomplete; MRP declaration tampered.',
      currentStage: 'Awaiting business correction by 20 Sep 2026',
      deadline: DateTime(2026, 9, 20),
      requiredAction: 'Re-inspection after correction deadline',
      timeline: [
        CaseTimelineEntry(
          title: 'Complaint Received',
          dateTime: DateTime(2026, 8, 28, 10, 0),
          isDone: true,
          isCurrent: false,
          actor: 'Citizen Portal',
        ),
        CaseTimelineEntry(
          title: 'Inspection Assigned',
          dateTime: DateTime(2026, 8, 30, 9, 0),
          isDone: true,
          isCurrent: false,
          actor: 'Controller Office',
        ),
        CaseTimelineEntry(
          title: 'Inspection Started',
          dateTime: DateTime(2026, 9, 2, 11, 0),
          isDone: true,
          isCurrent: false,
          actor: 'Rajesh Deshmukh',
        ),
        CaseTimelineEntry(
          title: 'Evidence Captured',
          dateTime: DateTime(2026, 9, 2, 11, 24),
          isDone: true,
          isCurrent: false,
          actor: 'Rajesh Deshmukh',
        ),
        CaseTimelineEntry(
          title: 'OCR Completed',
          dateTime: DateTime(2026, 9, 2, 11, 36),
          isDone: true,
          isCurrent: false,
          details: '5 declarations extracted',
          actor: 'AI Service',
        ),
        CaseTimelineEntry(
          title: 'Violation Detected',
          dateTime: DateTime(2026, 9, 2, 11, 37),
          isDone: true,
          isCurrent: false,
          details: '2 potential findings',
          actor: 'AI Service',
        ),
        CaseTimelineEntry(
          title: 'Inspector Verified',
          dateTime: DateTime(2026, 9, 2, 12, 5),
          isDone: true,
          isCurrent: false,
          details: '2 confirmed, 1 rejected',
          actor: 'Rajesh Deshmukh',
        ),
        CaseTimelineEntry(
          title: 'Improvement Notice Issued',
          dateTime: DateTime(2026, 9, 2, 12, 40),
          isDone: true,
          isCurrent: true,
          details: 'Correction deadline: 20 Sep 2026',
          actor: 'Rajesh Deshmukh',
        ),
        CaseTimelineEntry(
          title: 'Re-inspection',
          dateTime: DateTime(2026, 9, 21),
          isDone: false,
          isCurrent: false,
        ),
        CaseTimelineEntry(
          title: 'Resolved',
          dateTime: DateTime(2026, 9, 30),
          isDone: false,
          isCurrent: false,
        ),
      ],
    );

LegalCase _case2() => LegalCase(
      id: 'LM/2026/0155',
      productName: mockProducts[0].name,
      status: CaseStatus.awaitingPayment,
      openedAt: DateTime(2026, 8, 21),
      counterpartyName: 'ABC Traders',
      role: UserRole.business,
      violationSummary: 'MRP over-printing on detergent packs.',
      currentStage: 'Pay compounding penalty by 15 Sep 2026',
      deadline: DateTime(2026, 9, 15),
      requiredAction: 'Complete penalty payment',
      noticeType: NoticeType.compounding,
      penaltyAmount: 5000,
      timeline: [
        CaseTimelineEntry(
          title: 'Inspection',
          dateTime: DateTime(2026, 8, 21, 11, 0),
          isDone: true,
          isCurrent: false,
          actor: 'Rajesh Deshmukh',
        ),
        CaseTimelineEntry(
          title: 'Notice',
          dateTime: DateTime(2026, 8, 23, 10, 0),
          isDone: true,
          isCurrent: false,
          details: 'Improvement Notice NOT-841203',
          actor: 'Rajesh Deshmukh',
        ),
        CaseTimelineEntry(
          title: 'Correction Submitted',
          dateTime: DateTime(2026, 8, 29, 16, 0),
          isDone: true,
          isCurrent: false,
          actor: 'ABC Traders',
        ),
        CaseTimelineEntry(
          title: 'Re-inspection',
          dateTime: DateTime(2026, 9, 1, 12, 0),
          isDone: true,
          isCurrent: false,
          actor: 'Rajesh Deshmukh',
        ),
        CaseTimelineEntry(
          title: 'Compounding',
          dateTime: DateTime(2026, 9, 3, 11, 0),
          isDone: true,
          isCurrent: true,
          details: 'Compounding Order CO-2026-0451 — ₹5,000',
          actor: 'Controller Office',
        ),
        CaseTimelineEntry(
          title: 'Payment',
          dateTime: DateTime(2026, 9, 15),
          isDone: false,
          isCurrent: true,
          details: '₹5,000 penalty pending',
        ),
        CaseTimelineEntry(
          title: 'Closure',
          dateTime: DateTime(2026, 9, 20),
          isDone: false,
          isCurrent: false,
        ),
      ],
    );

LegalCase _case3() => LegalCase(
      id: 'LM/2026/0122',
      productName: mockProducts[4].name,
      status: CaseStatus.closed,
      openedAt: DateTime(2026, 7, 8),
      counterpartyName: 'XYZ Retail',
      role: UserRole.inspector,
      violationSummary: 'Missing country-of-origin declaration on import pack.',
      currentStage: 'Case closed',
      timeline: [
        CaseTimelineEntry(
          title: 'Inspection',
          dateTime: DateTime(2026, 7, 8, 10, 0),
          isDone: true,
          isCurrent: false,
        ),
        CaseTimelineEntry(
          title: 'Notice',
          dateTime: DateTime(2026, 7, 10, 10, 0),
          isDone: true,
          isCurrent: false,
        ),
        CaseTimelineEntry(
          title: 'Correction Verified',
          dateTime: DateTime(2026, 7, 22, 15, 0),
          isDone: true,
          isCurrent: false,
        ),
        CaseTimelineEntry(
          title: 'Resolved',
          dateTime: DateTime(2026, 7, 25, 12, 0),
          isDone: true,
          isCurrent: false,
          details: 'Corrected packaging verified',
        ),
      ],
    );

final mockCases = <LegalCase>[_case1(), _case2(), _case3()];

// ---------------------------------------------------------------------------
// Notices
// ---------------------------------------------------------------------------

Notice _improvementNotice1() => Notice(
      id: 'NOT-841203',
      caseId: 'LM/2026/0187',
      type: NoticeType.improvement,
      status: NoticeStatus.issued,
      productName: mockProducts[1].name,
      issuedDate: DateTime(2026, 9, 2, 12, 40),
      inspectionId: 'INSP-2026-00035',
      businessId: 'biz-005',
      businessName: 'Ganesh Kirana Stores',
      deadline: DateTime(2026, 9, 20),
      sections: const [
        NoticeSection(
          id: 'sec-1',
          citation: 'Rule 6(3), LM (PC) Rules, 2011',
          title: 'Consumer-care particulars',
        ),
        NoticeSection(
          id: 'sec-2',
          citation: 'Rule 2(m), LM (PC) Rules, 2011',
          title: 'Retail sale price declaration',
        ),
      ],
      violations: [
        mockAiViolation1().copyWith(status: ViolationStatus.accepted),
        mockAiViolation2().copyWith(status: ViolationStatus.accepted),
      ],
      isAiDraft: false,
      bodyText:
          'Whereas an inspection was carried out at the above-mentioned '
          'premises on 02/09/2026 and certain contraventions of the Legal '
          'Metrology Act, 2009 and rules made thereunder were observed in '
          'respect of pre-packaged commodities offered for retail sale, you '
          'are hereby directed to rectify the said contraventions on or '
          'before 20/09/2026 and submit a compliance report with photographic '
          'evidence of corrected packaging.',
    );

Notice _compoundingNotice() => Notice(
      id: 'NOT-772410',
      caseId: 'LM/2026/0155',
      type: NoticeType.compounding,
      status: NoticeStatus.consentGiven,
      productName: mockProducts[0].name,
      issuedDate: DateTime(2026, 9, 3, 11, 0),
      inspectionId: 'INSP-2026-00031',
      businessId: 'biz-001',
      businessName: 'ABC Traders',
      deadline: DateTime(2026, 9, 15),
      penaltyAmount: 5000,
      sections: const [
        NoticeSection(
          id: 'sec-3',
          citation: 'Section 46, Legal Metrology Act, 2009',
          title: 'Compounding of offences',
        ),
      ],
      violations: [
        mockAiViolation1().copyWith(status: ViolationStatus.accepted),
      ],
      isAiDraft: false,
      bodyText:
          'Upon application by the accused and with the consent of the '
          'controlling authority, the offence may be compounded on payment '
          'of ₹5,000 on or before 15/09/2026.',
    );

Notice _seizureNotice() => Notice(
      id: 'NOT-660151',
      caseId: 'LM/2026/0110',
      type: NoticeType.seizure,
      status: NoticeStatus.delivered,
      productName: mockProducts[2].name,
      issuedDate: DateTime(2026, 8, 12, 14, 0),
      inspectionId: 'INSP-2026-00028',
      businessId: 'biz-003',
      businessName: 'XYZ Retail',
      deadline: DateTime(2026, 9, 10),
      sections: const [
        NoticeSection(
          id: 'sec-4',
          citation: 'Section 22, Legal Metrology Act, 2009',
          title: 'Power to seize',
        ),
      ],
      violations: [
        mockAiViolation3().copyWith(status: ViolationStatus.accepted),
      ],
      isAiDraft: false,
      bodyText:
          'The following pre-packaged commodity has been seized under '
          'Section 22 of the Legal Metrology Act, 2009 for non-standard '
          'declaration of quantity. A panchanama was prepared at the time '
          'of seizure in the presence of two independent witnesses.',
    );

final mockNotices = <Notice>[
  _improvementNotice1(),
  _compoundingNotice(),
  _seizureNotice(),
];

// ---------------------------------------------------------------------------
// Offence history
// ---------------------------------------------------------------------------

OffenceHistory offenceHistoryRepeat() => OffenceHistory(
      productId: 'prd-001',
      matchedProductName: 'Surf Excel Easy Wash Detergent Powder 1 kg',
      tier: OffenceTier.second,
      checkedAt: DateTime(2026, 8, 21, 12, 2),
      matchConfidence: 0.97,
      records: [
        OffenceRecord(
          caseId: 'LM/2026/0155',
          businessName: 'ABC Traders, Laxmi Road, Pune',
          location: 'Pune, Maharashtra',
          date: DateTime(2026, 6, 14),
          violationSummary: 'MRP declaration not as per printed computation',
          caseStatus: 'Compounding completed',
        ),
        OffenceRecord(
          caseId: 'LM/2025/0912',
          businessName: 'Sai Provisions, Market Yard, Pune',
          location: 'Pune, Maharashtra',
          date: DateTime(2025, 11, 2),
          violationSummary: 'Net quantity declaration non-standard',
          caseStatus: 'Closed',
        ),
      ],
    );

OffenceHistory offenceHistoryNone(String productId) => OffenceHistory(
      productId: productId,
      matchedProductName: '—',
      tier: OffenceTier.none,
      checkedAt: DateTime.now(),
      records: const [],
    );

// ---------------------------------------------------------------------------
// Self-check reports (PRIVATE — business-only visibility)
// ---------------------------------------------------------------------------

SelfCheckReport selfCheckReport1() => SelfCheckReport(
      id: 'SC-482911',
      productName: 'House Blend Chilli Powder 500 g (in-house pack)',
      performedAt: DateTime(2026, 9, 4, 9, 40),
      isCompliant: false,
      issues: [
        const SelfCheckIssue(
          field: 'Consumer care details',
          issue: 'Consumer-care declaration may require correction.',
          requirement:
              'Rule 6(3), LM (Packaged Commodities) Rules, 2011 requires a '
              'consumer-care declaration with phone and e-mail.',
          severity: ViolationSeverity.medium,
          recommendedCorrection:
              'Add the required consumer-care declaration in the prescribed format.',
        ),
        const SelfCheckIssue(
          field: 'Month & year of manufacture',
          issue: 'Manufacturing date could not be read with confidence.',
          requirement:
              'Rule 6(1)(b) requires month & year of manufacture in leading '
              'characters.',
          severity: ViolationSeverity.low,
          recommendedCorrection:
              'Re-print the date code with higher contrast or larger characters.',
        ),
      ],
      imagePaths: const [],
    );

SelfCheckReport selfCheckReport2() => SelfCheckReport(
      id: 'SC-471208',
      productName: 'Packaged Basmati Rice 5 kg (house brand)',
      performedAt: DateTime(2026, 8, 27, 18, 5),
      isCompliant: true,
      issues: const [],
      imagePaths: const [],
    );

final mockSelfCheckHistory = <SelfCheckReport>[selfCheckReport1(), selfCheckReport2()];

// ---------------------------------------------------------------------------
// Payments
// ---------------------------------------------------------------------------

final mockPayments = <PaymentRecord>[
  PaymentRecord(
    id: 'PAY-48291044',
    caseId: 'LM/2026/0155',
    description: 'Compounding penalty — Improvement Notice NOT-772410',
    amount: 5000,
    status: PaymentStatus.pendingVerification,
    createdAt: DateTime(2026, 9, 3, 12, 0),
  ),
  PaymentRecord(
    id: 'PAY-45100231',
    caseId: 'LM/2026/0122',
    description: 'Compounding penalty — Improvement Notice NOT-660998',
    amount: 2500,
    status: PaymentStatus.success,
    createdAt: DateTime(2026, 7, 26, 15, 30),
    completedAt: DateTime(2026, 7, 26, 15, 32),
  ),
];

// ---------------------------------------------------------------------------
// Notice section library (Legal Knowledge Base subset — Member 5)
// ---------------------------------------------------------------------------

const noticeSectionLibrary = <NoticeSection>[
  NoticeSection(
    id: 'lib-1',
    citation: 'Section 18(1), Legal Metrology Act, 2009',
    title: 'Registration of importers / manufacturers',
  ),
  NoticeSection(
    id: 'lib-2',
    citation: 'Rule 6(1), LM (Packaged Commodities) Rules, 2011',
    title: 'Mandatory declarations on retail packages',
  ),
  NoticeSection(
    id: 'lib-3',
    citation: 'Rule 6(3), LM (Packaged Commodities) Rules, 2011',
    title: 'Consumer-care particulars',
  ),
  NoticeSection(
    id: 'lib-4',
    citation: 'Rule 2(m), LM (Packaged Commodities) Rules, 2011',
    title: 'Retail sale price (MRP) declaration',
  ),
  NoticeSection(
    id: 'lib-5',
    citation: 'Rule 7, LM (Packaged Commodities) Rules, 2011',
    title: 'Standard units, symbols and numerals',
  ),
  NoticeSection(
    id: 'lib-6',
    citation: 'Section 22, Legal Metrology Act, 2009',
    title: 'Power of inspector to seize',
  ),
  NoticeSection(
    id: 'lib-7',
    citation: 'Section 32, Legal Metrology Act, 2009',
    title: 'Panchanama / seizure procedure',
  ),
  NoticeSection(
    id: 'lib-8',
    citation: 'Section 46, Legal Metrology Act, 2009',
    title: 'Compounding of offences',
  ),
];

/// Demo business profile card data (shown in business dashboard).
const demoSelfCheckTip =
    'Photograph 2–3 clear sides of the package. Ensure the MRP, net '
    'quantity and consumer-care details are legible for accurate analysis.';
