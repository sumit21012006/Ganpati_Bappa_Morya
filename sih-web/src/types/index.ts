export type UserRole = 'CITIZEN' | 'BUSINESS' | 'INSPECTOR' | 'CONTROLLER';

export interface AuthUser {
  id: string;
  name: string;
  email: string;
  mobile?: string;
  badgeId?: string;
  role: UserRole;
  rewardPoints: number;
  upiVpa?: string;
  createdAt: string;
}

export type CaseStatus = 
  | 'RECEIVED'
  | 'ASSIGNED'
  | 'INSPECTED'
  | 'NOTICE_ISSUED'
  | 'COMPOUNDED'
  | 'PROSECUTION'
  | 'RESOLVED';

export type NoticeType = 'IMPROVEMENT' | 'SEIZURE' | 'PANCHANAMA' | 'COMPOUNDED';

export type NoticeStatus = 'PENDING' | 'DISPUTED' | 'APPROVED' | 'REJECTED' | 'PAID';

export interface Business {
  id: string;
  name: string;
  address: string;
  gstin: string;
  tradeRegNo?: string;
  jurisdictionCircle: string;
  geoLat?: number;
  geoLng?: number;
  turnoverBand?: string;
}

export interface Complaint {
  id: string;
  citizenId: string;
  citizenName: string;
  citizenMobile: string;
  citizenUpiVpa: string;
  businessId?: string;
  retailerNameText: string;
  retailerAddressText: string;
  channel: 'OFFLINE_STORE' | 'ECOMMERCE_PLATFORM';
  category: string;
  statementOfFact: string;
  photoUrls: string[];
  invoiceUrl?: string;
  status: CaseStatus;
  createdAt: string;
  updatedAt: string;
  estimatedRewardPoints: number;
  rewardPointsStatus: 'PENDING_COMPOUNDING' | 'UNDER_VERIFICATION' | 'CREDITED' | 'REJECTED';
  rewardTransactionRef?: string;
}

export interface Inspection {
  id: string;
  caseId: string;
  inspectorId: string;
  inspectorName: string;
  inspectorBadge: string;
  businessId: string;
  businessName: string;
  visitDate: string;
  status: string;
  notes: string;
  seizedQuantity?: number;
  weighingScaleVerified?: boolean;
  witnessCount?: number;
  witnessNames?: string[];
  photoUrls: string[];
  gpsLat: number;
  gpsLng: number;
  sha256Hash: string;
  dscSignedAt?: string;
}

export interface OcrResult {
  id: string;
  inspectionId?: string;
  imageUrls: string[];
  extractedFields: {
    mrp?: string;
    netQuantity?: string;
    mfgDate?: string;
    expDate?: string;
    manufacturerName?: string;
    manufacturerAddress?: string;
    consumerCareDetails?: string;
    countryOfOrigin?: string;
  };
  violations: Array<{
    ruleSection: string;
    severity: 'MINOR' | 'MODERATE' | 'CRITICAL' | 'SEVERE';
    description: string;
  }>;
  offenceTier: 'FIRST_OFFENCE' | 'SECOND_OFFENCE';
}

export interface Notice {
  id: string;
  caseId: string;
  dinNumber: string;
  type: NoticeType;
  businessName: string;
  gstin: string;
  violatingProduct: string;
  sectionRefs: string[];
  status: NoticeStatus;
  issuedDate: string;
  deadlineDate: string;
  penaltyAmount: number;
  rewardPointsAllocated: number;
  pdfUrl?: string;
  signatureUrl?: string;
  offenceTier: 'FIRST_OFFENCE' | 'SECOND_OFFENCE';
  forensicEvidence?: {
    originalMrp: string;
    overwrittenMrp: string;
    tamperType: string;
    stampedDate: string;
    flaggedDiff: string;
    exifDetails: string;
    factoryBatch: string;
    originalImage: string;
    tamperedImage: string;
  };
}

export interface SupplyChainLink {
  id: string;
  sourceBusinessId: string;
  sourceBusinessName: string;
  sourceAddress: string;
  namedBusinessId: string;
  namedBusinessName: string;
  namedBusinessAddress: string;
  contrabandParameter: string;
  status: 'PENDING_ASSIGNMENT' | 'ASSIGNED' | 'RAID_SCHEDULED' | 'RESOLVED';
  assignedInspectorId?: string;
  assignedInspectorName?: string;
  jurisdiction: string;
}

export interface DashboardStats {
  totalInspections: number;
  totalInspectionsTarget: number;
  firstOffencesLogged: number;
  firstOffencesNoticesServed: number;
  firstOffencesUnderVerification: number;
  secondOffencesLogged: number;
  secondOffencesChargesheets: number;
  secondOffencesSeizuresPending: number;
  penaltiesRecoveredRupees: string;
  citizenRewardsPaidPoints: number;
  activeOfficersCount: number;
  regionalRadar: Array<{
    region: string;
    alertLevel: 'High Alert' | 'Moderate Watch' | 'Compliant';
    inspections: number;
    violations: number;
    recoveryRupees: string;
    slaRatePercent: number;
  }>;
}
