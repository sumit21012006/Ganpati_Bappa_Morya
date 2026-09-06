import { Complaint, DashboardStats, Notice, SupplyChainLink } from '@/types';

// Mock initial complaints
export const MOCK_COMPLAINTS: Complaint[] = [
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
    statementOfFact: 'Purchased bottle from QuickMart Supermarket shelf. Bottle felt visibly underweight compared to adjacent brands. Upon laboratory calibrated scale measurement in our cooperative society test bench, gross package weighed 925g with net oil estimated at 848ml vs statutory mandatory 1000ml declaration.',
    photoUrls: [
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=60',
      'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=600&auto=format&fit=crop&q=60',
    ],
    invoiceUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600&auto=format&fit=crop&q=60',
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
    retailerAddressText: 'Andheri West, Mumbai, Maharashtra',
    channel: 'OFFLINE_STORE',
    category: 'Sec 36 Net Qty Deficit 0.320g',
    statementOfFact: '5kg Basmati Rice bag weighed on calibrated digital scale was short by 320 grams. Exceeds Maximum Permissible Error threshold under Second Schedule of PCR 2011.',
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
    statementOfFact: 'Almonds 250g pack missing statutory unit sale price declaration (Rs per gram) required under mandatory PCR Rule 6(11) amendment.',
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
    statementOfFact: 'Water bottle 1000ml sold at Rs 70 inside cinema hall whereas manufacturer MRP printed on original container was Rs 20.',
    photoUrls: [],
    status: 'RESOLVED',
    createdAt: '2024-08-18T14:10:00Z',
    updatedAt: '2024-08-28T18:00:00Z',
    estimatedRewardPoints: 2750,
    rewardPointsStatus: 'CREDITED',
    rewardTransactionRef: '99812400192831',
  },
];

// Mock Dashboard Stats
export const MOCK_DASHBOARD_STATS: DashboardStats = {
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

// Mock Supply Chain Links
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

// Mock Compounding Orders & Dossiers for Controller Review Desk
export const MOCK_NOTICES: Notice[] = [
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
      factoryBatch: 'No. A231 | Mfd 09/2024 | Hindustan CleanCare Works Ltd.',
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

// Helper functions for API calls (Mocks API response with latency)
export async function fetchCitizenComplaints(): Promise<Complaint[]> {
  return new Promise((resolve) => {
    setTimeout(() => resolve([...MOCK_COMPLAINTS]), 300);
  });
}

export async function submitCitizenComplaint(data: Partial<Complaint>): Promise<Complaint> {
  return new Promise((resolve) => {
    const newComplaint: Complaint = {
      id: `LM-2024-MH-${Math.floor(1000 + Math.random() * 9000)}`,
      citizenId: 'cit_101',
      citizenName: data.citizenName || 'Arjun Suresh Sharma',
      citizenMobile: data.citizenMobile || '+91 98450 XXXXX',
      citizenUpiVpa: data.citizenUpiVpa || 'arjun.sharma@okaxis',
      businessId: data.businessId,
      retailerNameText: data.retailerNameText || 'Store Merchant',
      retailerAddressText: data.retailerAddressText || 'Local Market',
      channel: data.channel || 'OFFLINE_STORE',
      category: data.category || 'General Metrology Violation',
      statementOfFact: data.statementOfFact || 'Visual label and measurement discrepancy observed.',
      photoUrls: data.photoUrls || [],
      invoiceUrl: data.invoiceUrl,
      status: 'RECEIVED',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      estimatedRewardPoints: 2500,
      rewardPointsStatus: 'PENDING_COMPOUNDING',
    };
    MOCK_COMPLAINTS.unshift(newComplaint);
    setTimeout(() => resolve(newComplaint), 500);
  });
}

export async function fetchDashboardStats(): Promise<DashboardStats> {
  return new Promise((resolve) => {
    setTimeout(() => resolve({ ...MOCK_DASHBOARD_STATS }), 300);
  });
}

export async function fetchCompoundingNotices(): Promise<Notice[]> {
  return new Promise((resolve) => {
    setTimeout(() => resolve([...MOCK_NOTICES]), 300);
  });
}

export async function updateNoticeStatus(id: string, status: Notice['status']): Promise<Notice> {
  return new Promise((resolve, reject) => {
    const notice = MOCK_NOTICES.find((n) => n.id === id);
    if (notice) {
      notice.status = status;
      setTimeout(() => resolve({ ...notice }), 400);
    } else {
      reject(new Error('Notice not found'));
    }
  });
}
