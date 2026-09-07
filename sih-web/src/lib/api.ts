/**
 * api.ts — Main API layer for sih-web.
 *
 * All functions now call the real NestJS backend at NEXT_PUBLIC_API_BASE_URL.
 * Static MOCK_* constants are kept only where backend endpoints don't exist yet
 * (documented as BACKEND BLOCKER comments).
 */
import { Complaint, DashboardStats, Notice, SupplyChainLink } from '@/types';
import { fetchComplaintsFromBackend, submitComplaintToBackend } from '@/lib/api/complaints';
import { fetchDashboardStatsFromBackend, fetchSupplyChainLinks } from '@/lib/api/controller';
import { fetchNoticesFromBackend, updateNoticeStatusOnBackend } from '@/lib/api/notices';
import { ApiError } from '@/lib/apiClient';

export { fetchSupplyChainLinks };


// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — kept only for features with no backend endpoint yet
// ─────────────────────────────────────────────────────────────────────────────

/**
 * BACKEND BLOCKER: No GET /api/v1/controller/supply-chain-links endpoint.
 * Keeping as static mock until Member 1 adds the list endpoint.
 */
export const MOCK_SUPPLY_CHAIN_LINKS: SupplyChainLink[] = [
  {
    id: 'link_01',
    sourceBusinessId: 'biz_05',
    sourceBusinessName: 'Shree Ganesh Kirana',
    sourceAddress: 'Naupada, Thane West',
    namedBusinessId: 'biz_10',
    namedBusinessName: 'Bhoomi Agro Packagers & Mills Pvt Ltd',
    namedBusinessAddress: 'Plot C-14, MIDC Taloja, Raigad Dist.',
    contrabandParameter: 'Mustard Oil 1L Net Qty Shortfall (12.4% deficit against Rule 24)',
    status: 'PENDING_ASSIGNMENT',
    jurisdiction: 'Raigad / MIDC Circle',
  },
  {
    id: 'link_02',
    sourceBusinessId: 'biz_06',
    sourceBusinessName: 'FreshDaily E-Com Hub',
    sourceAddress: 'Bandra Kurla Complex, Mumbai',
    namedBusinessId: 'biz_11',
    namedBusinessName: 'Apex Global Imports Pvt Ltd',
    namedBusinessAddress: 'Okhla Industrial Area Phase-III, New Delhi',
    contrabandParameter: 'Missing Country of Origin & Unregistered Importer MRP sticker',
    status: 'PENDING_ASSIGNMENT',
    jurisdiction: 'Inter-State / Delhi Hub',
  },
  {
    id: 'link_03',
    sourceBusinessId: 'biz_07',
    sourceBusinessName: 'Modern Supermarket',
    sourceAddress: 'Andheri Lokhandwala, Mumbai',
    namedBusinessId: 'biz_12',
    namedBusinessName: 'Zenith Health Supplements LLP',
    namedBusinessAddress: 'Kalyan Bhiwandi Logistics Park',
    contrabandParameter: 'Unapproved Nutritional Metric Declarations & Missing Batch No',
    status: 'RAID_SCHEDULED',
    assignedInspectorId: 'insp_412',
    assignedInspectorName: 'Insp. S. Kadam (Badge #MH-LM-412)',
    jurisdiction: 'Thane Circle',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// REAL API FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Fetch citizen complaints from backend.
 * Falls back to mock data if backend is unreachable.
 */
export async function fetchCitizenComplaints(): Promise<Complaint[]> {
  try {
    return await fetchComplaintsFromBackend();
  } catch (err) {
    console.warn('[api] fetchCitizenComplaints: backend unreachable, using mocks.', err);
    return MOCK_COMPLAINTS_FALLBACK;
  }
}

/**
 * Submit a new citizen complaint to the NestJS backend.
 */
export async function submitCitizenComplaint(
  data: Partial<Complaint>
): Promise<Complaint> {
  const dto = {
    citizenId: data.citizenId || 'citizen_web',
    citizenName: data.citizenName || 'Citizen',
    citizenMobile: data.citizenMobile || '',
    citizenUpiVpa: data.citizenUpiVpa || '',
    retailerNameText: data.retailerNameText || 'Unknown Retailer',
    retailerAddressText: data.retailerAddressText || '',
    channel: (data.channel || 'OFFLINE_STORE') as 'OFFLINE_STORE' | 'ECOMMERCE_PLATFORM',
    category: data.category || 'General Metrology Violation',
    statementOfFact: data.statementOfFact || '',
    photoUrls: data.photoUrls || [],
    invoiceUrl: data.invoiceUrl,
  };

  try {
    return await submitComplaintToBackend(dto);
  } catch (err) {
    console.error('[api] submitCitizenComplaint failed:', err);
    // Rethrow so UI can show error
    if (err instanceof ApiError) {
      throw new Error(`Complaint submission failed: ${err.message}`);
    }
    throw err;
  }
}

/**
 * Fetch controller dashboard statistics from NestJS backend.
 */
export async function fetchDashboardStats(): Promise<DashboardStats> {
  try {
    return await fetchDashboardStatsFromBackend();
  } catch (err) {
    console.warn('[api] fetchDashboardStats: backend unreachable, using mocks.', err);
    return MOCK_DASHBOARD_STATS_FALLBACK;
  }
}

/**
 * Fetch compounding notices / legal notices from NestJS backend.
 */
export async function fetchCompoundingNotices(): Promise<Notice[]> {
  try {
    const notices = await fetchNoticesFromBackend();
    // Return all if backend has data; fall back to mock if empty
    return notices.length > 0 ? notices : MOCK_NOTICES_FALLBACK;
  } catch (err) {
    console.warn('[api] fetchCompoundingNotices: backend unreachable, using mocks.', err);
    return MOCK_NOTICES_FALLBACK;
  }
}

/**
 * Update notice status on NestJS backend.
 * Used for basic status updates (not controller approval — use compoundingAction for that).
 */
export async function updateNoticeStatus(
  id: string,
  status: Notice['status'],
  comments?: string
): Promise<Notice> {
  try {
    return await updateNoticeStatusOnBackend(id, status, comments);
  } catch (err) {
    console.error('[api] updateNoticeStatus failed:', err);
    // Optimistic fallback — find and update in mock list
    const notice = MOCK_NOTICES_FALLBACK.find((n) => n.id === id);
    if (notice) {
      notice.status = status;
      return { ...notice };
    }
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FALLBACK MOCK DATA (used when backend is offline)
// ─────────────────────────────────────────────────────────────────────────────

const MOCK_COMPLAINTS_FALLBACK: Complaint[] = [
  {
    id: 'LM-2024-MH-0842',
    citizenId: 'cit_101',
    citizenName: 'Arjun Suresh Sharma',
    citizenMobile: '+91 98450 XXXXX',
    citizenUpiVpa: 'arjun.sharma@okaxis',
    businessId: 'biz_02',
    retailerNameText: 'Blinkit Dark Store Hub',
    retailerAddressText: 'SuperStore Retailers LLP, Hiranandani Powai, Mumbai',
    channel: 'ECOMMERCE_PLATFORM',
    category: 'Rule 16(1) Dual MRP Violation',
    statementOfFact: 'Purchased bottle from QuickMart. MRP sticker tampered.',
    photoUrls: [],
    status: 'COMPOUNDED',
    createdAt: '2024-10-12T10:30:00Z',
    updatedAt: '2024-10-25T14:20:00Z',
    estimatedRewardPoints: 5000,
    rewardPointsStatus: 'CREDITED',
    rewardTransactionRef: '68190082147732',
  },
  {
    id: 'LM-2024-MH-9122',
    citizenId: 'cit_101',
    citizenName: 'Arjun Suresh Sharma',
    citizenMobile: '+91 98450 XXXXX',
    citizenUpiVpa: 'arjun.sharma@okaxis',
    retailerNameText: 'Radhe Krishna Supermarket',
    retailerAddressText: 'Andheri West, Mumbai',
    channel: 'OFFLINE_STORE',
    category: 'Sec 36 Net Qty Deficit 0.320g',
    statementOfFact: '5kg Basmati Rice short by 320g.',
    photoUrls: [],
    status: 'ASSIGNED',
    createdAt: '2024-10-20T11:15:00Z',
    updatedAt: '2024-10-21T09:00:00Z',
    estimatedRewardPoints: 2500,
    rewardPointsStatus: 'PENDING_COMPOUNDING',
  },
  {
    id: 'LM-2024-MH-9340',
    citizenId: 'cit_101',
    citizenName: 'Arjun Suresh Sharma',
    citizenMobile: '+91 98450 XXXXX',
    citizenUpiVpa: 'arjun.sharma@okaxis',
    retailerNameText: 'Zepto Fulfillment Centre',
    retailerAddressText: 'BKC Hub, Mumbai',
    channel: 'ECOMMERCE_PLATFORM',
    category: 'Rule 6 Missing Unit Sale Price',
    statementOfFact: 'Almonds 250g pack missing unit sale price.',
    photoUrls: [],
    status: 'RECEIVED',
    createdAt: '2024-11-02T16:45:00Z',
    updatedAt: '2024-11-02T16:45:00Z',
    estimatedRewardPoints: 1500,
    rewardPointsStatus: 'UNDER_VERIFICATION',
  },
  {
    id: 'LM-2024-MH-0119',
    citizenId: 'cit_101',
    citizenName: 'Arjun Suresh Sharma',
    citizenMobile: '+91 98450 XXXXX',
    citizenUpiVpa: 'arjun.sharma@okaxis',
    retailerNameText: 'Cinepolis Multiplex',
    retailerAddressText: 'Viviana Mall, Thane West',
    channel: 'OFFLINE_STORE',
    category: 'Rule 18(1) Overcharging Dual MRP Rs 70',
    statementOfFact: 'Water bottle sold at Rs 70 vs MRP Rs 20.',
    photoUrls: [],
    status: 'RESOLVED',
    createdAt: '2024-08-18T14:10:00Z',
    updatedAt: '2024-08-28T18:00:00Z',
    estimatedRewardPoints: 2750,
    rewardPointsStatus: 'CREDITED',
    rewardTransactionRef: '99812400192831',
  },
];

const MOCK_DASHBOARD_STATS_FALLBACK: DashboardStats = {
  totalInspections: 14892,
  totalInspectionsTarget: 18000,
  firstOffencesLogged: 2410,
  firstOffencesNoticesServed: 1890,
  firstOffencesUnderVerification: 520,
  secondOffencesLogged: 342,
  secondOffencesChargesheets: 312,
  secondOffencesSeizuresPending: 30,
  penaltiesRecoveredRupees: '8.42 Cr',
  citizenRewardsPaidPoints: 842000,
  activeOfficersCount: 1428,
  regionalRadar: [
    {
      region: 'Mumbai Suburban (Zones 1-4)',
      alertLevel: 'High Alert',
      inspections: 4120,
      violations: 620,
      recoveryRupees: '2.10 Cr',
      slaRatePercent: 94.2,
    },
    {
      region: 'Pune Metro & Pimpri-Chinchwad',
      alertLevel: 'Moderate Watch',
      inspections: 3210,
      violations: 480,
      recoveryRupees: '1.60 Cr',
      slaRatePercent: 91.8,
    },
    {
      region: 'Nagpur & Vidarbha Hub',
      alertLevel: 'Compliant',
      inspections: 1840,
      violations: 210,
      recoveryRupees: '82.0 L',
      slaRatePercent: 96.5,
    },
    {
      region: 'Nashik & Sambhajinagar Belt',
      alertLevel: 'Compliant',
      inspections: 1420,
      violations: 165,
      recoveryRupees: '54.5 L',
      slaRatePercent: 98.1,
    },
  ],
};

export const MOCK_NOTICES_FALLBACK: Notice[] = [
  {
    id: 'CO-2024-9041',
    caseId: 'case_9041',
    dinNumber: 'DIN-2024-MH-9104',
    type: 'COMPOUNDED',
    businessName: 'Apex Retailers & Mart LLP',
    gstin: '27AABCU9603R1ZN',
    violatingProduct: 'Surf Super Wash 2kg Powder',
    sectionRefs: ['Rule 16(1)', 'Sec 36(1)'],
    status: 'PENDING',
    issuedDate: '2024-10-18T14:21:04Z',
    deadlineDate: '2024-11-02T23:59:59Z',
    penaltyAmount: 50000,
    rewardPointsAllocated: 5000,
    offenceTier: 'FIRST_OFFENCE',
    forensicEvidence: {
      originalMrp: 'Rs 320.00 incl of taxes',
      overwrittenMrp: 'Rs 399.00',
      tamperType: 'Illegal Affixed Sticker Overwriting',
      stampedDate: '09/2024',
      flaggedDiff: '+ Rs 79.00 (+24.6% Hike)',
      exifDetails: 'EXIF: 18-OCT-2024 14:21:04 | CAM-JMO-94',
      factoryBatch: 'No. A231 | Mfd 09/2024',
      originalImage: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=60',
      tamperedImage: 'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=600&auto=format&fit=crop&q=60',
    },
  },
  {
    id: 'CO-2024-8994',
    caseId: 'case_8994',
    dinNumber: 'DIN-2024-MH-9105',
    type: 'COMPOUNDED',
    businessName: 'Kisan Mega Agro Wholesalers',
    gstin: '27AADCK4490Q1ZB',
    violatingProduct: 'Golden Harvest Basmati Rice 5kg',
    sectionRefs: ['Sec 36(2)', 'Rule 24'],
    status: 'DISPUTED',
    issuedDate: '2024-10-15T09:40:00Z',
    deadlineDate: '2024-10-30T23:59:59Z',
    penaltyAmount: 100000,
    rewardPointsAllocated: 10000,
    offenceTier: 'SECOND_OFFENCE',
  },
  {
    id: 'CO-2024-8977',
    caseId: 'case_8977',
    dinNumber: 'DIN-2024-MH-9088',
    type: 'COMPOUNDED',
    businessName: 'QuickKart Direct Warehousing Pvt Ltd',
    gstin: '27AABCZ1209M1Z0',
    violatingProduct: 'California Supreme Almond Better 250g',
    sectionRefs: ['Rule 6(1)(a)'],
    status: 'APPROVED',
    issuedDate: '2024-10-10T16:00:00Z',
    deadlineDate: '2024-10-25T23:59:59Z',
    penaltyAmount: 25000,
    rewardPointsAllocated: 2500,
    offenceTier: 'FIRST_OFFENCE',
  },
];

// Keep MOCK_NOTICES export as alias to fallback for backward compat
export const MOCK_NOTICES = MOCK_NOTICES_FALLBACK;
