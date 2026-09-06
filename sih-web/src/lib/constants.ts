import { CaseStatus, NoticeType, NoticeStatus } from '@/types';

export const CASE_STATUS_MAP: Record<CaseStatus, { label: string; color: string; bg: string; border: string }> = {
  RECEIVED: { label: 'Complaint Received', color: 'text-blue-700 dark:text-blue-400', bg: 'bg-blue-50 dark:bg-blue-950/50', border: 'border-blue-200 dark:border-blue-800' },
  ASSIGNED: { label: 'Inspector Assigned', color: 'text-amber-700 dark:text-amber-400', bg: 'bg-amber-50 dark:bg-amber-950/50', border: 'border-amber-200 dark:border-amber-800' },
  INSPECTED: { label: 'Inspected', color: 'text-purple-700 dark:text-purple-400', bg: 'bg-purple-50 dark:bg-purple-950/50', border: 'border-purple-200 dark:border-purple-800' },
  NOTICE_ISSUED: { label: 'Notice Issued', color: 'text-orange-700 dark:text-orange-400', bg: 'bg-orange-50 dark:bg-orange-950/50', border: 'border-orange-200 dark:border-orange-800' },
  COMPOUNDED: { label: 'Compounded', color: 'text-emerald-700 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-950/50', border: 'border-emerald-200 dark:border-emerald-800' },
  PROSECUTION: { label: 'Prosecution Filed', color: 'text-rose-700 dark:text-rose-400', bg: 'bg-rose-50 dark:bg-rose-950/50', border: 'border-rose-200 dark:border-rose-800' },
  RESOLVED: { label: 'Case Resolved', color: 'text-cyan-700 dark:text-cyan-400', bg: 'bg-cyan-50 dark:bg-cyan-950/50', border: 'border-cyan-200 dark:border-cyan-800' },
};

export const NOTICE_TYPE_MAP: Record<NoticeType, { label: string; stage: number; severity: string }> = {
  IMPROVEMENT: { label: 'Improvement Notice (Form I)', stage: 1, severity: 'MINOR / FIRST WARNING' },
  SEIZURE: { label: 'Seizure Memo & Form V', stage: 2, severity: 'MODERATE / SAMPLE SEIZURE' },
  PANCHANAMA: { label: 'Independent Panchanama Notice', stage: 3, severity: 'CRITICAL / WITNESSED' },
  COMPOUNDED: { label: 'Compounded Penalty Order', stage: 4, severity: 'SEVERELY FINED' },
};

export const NOTICE_STATUS_MAP: Record<NoticeStatus, { label: string; color: string }> = {
  PENDING: { label: 'Awaiting Controller Approval', color: 'text-amber-500 bg-amber-500/10 border-amber-500/30' },
  DISPUTED: { label: 'Disputed by Merchant', color: 'text-purple-500 bg-purple-500/10 border-purple-500/30' },
  APPROVED: { label: 'Approved & Signed', color: 'text-blue-500 bg-blue-500/10 border-blue-500/30' },
  REJECTED: { label: 'Returned for Revision', color: 'text-rose-500 bg-rose-500/10 border-rose-500/30' },
  PAID: { label: 'Penalty Paid & Compounded', color: 'text-emerald-500 bg-emerald-500/10 border-emerald-500/30' },
};

export const VIOLATION_CATEGORIES = [
  'Dual MRP Sticker / Altered Price (Rule 16(1))',
  'Short Weight / Quantity Deficit beyond permissible error (Section 36(1) / PCR Rule 12)',
  'Missing Date of Manufacture / Packaging (Rule 6(1)(d))',
  'Missing Country of Origin / Importer Details (Rule 6(1)(a))',
  'Absence of Valid Helpline / Consumer Care Contact (Rule 6(1)(e))',
  'Non-standard Unit Sale Price Declaration (Rule 6(11))',
  'Repeat Offence / Serial Violation (Section 36(2))',
];

export const MOCK_BUSINESSES = [
  {
    id: 'biz_01',
    name: 'QuickMart Supermarket Pvt Ltd',
    address: 'Hub Town, Andheri East, Zone IV, Mumbai, MH - 400069',
    gstin: '27AACQ4921C1Z0',
    tradeRegNo: 'MHLM/2023/88902',
    jurisdictionCircle: 'Zone IV (Andheri Div)',
  },
  {
    id: 'biz_02',
    name: 'Blinkit Dark Store Hub',
    address: 'SuperStore Retailers LLP, Hiranandani Powai, Mumbai - 400076',
    gstin: '27AABCU9603R1ZN',
    tradeRegNo: 'LMO Retail Reg: MH-RET-2022-B1190',
    jurisdictionCircle: 'LMO Mumbai Central (Zone 4)',
  },
  {
    id: 'biz_03',
    name: 'Apex Retailers & Mart LLP',
    address: 'Gala No 14, Phoenix Market City Wing R, LBS Marg, Kurla West, Mumbai 400070',
    gstin: '27AABCU9603R1ZN',
    tradeRegNo: 'LMO Retail Reg: PH-RET-2022-B1190',
    jurisdictionCircle: 'LMO Zone 4, Mumbai Central',
  },
  {
    id: 'biz_04',
    name: 'Zepto Fulfillment Centre',
    address: 'BKC Hub, Bandra East, Mumbai - 400051',
    gstin: '27AABCZ1209M1Z0',
    tradeRegNo: 'LMO Retail Reg: MH-RET-2023-Z8810',
    jurisdictionCircle: 'LMO Zone 7, BKC Div',
  },
];
