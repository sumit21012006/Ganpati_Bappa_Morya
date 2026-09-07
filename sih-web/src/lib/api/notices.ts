/**
 * Notices API — wraps NestJS /api/v1/notices endpoints.
 *
 * Schema notes:
 * - Backend notice `type` is lowercase ('improvement', 'compounded')
 * - Backend notice `status` is lowercase ('issued', 'pending', 'approved')
 * - Frontend Notice type uses uppercase enums
 */
import { apiGet, apiPatch } from '@/lib/apiClient';
import { Notice, NoticeType, NoticeStatus } from '@/types';

interface BackendNotice {
  id: string;
  caseId?: string;
  businessId?: string;
  businessName?: string;
  productName?: string;
  type?: string;
  status?: string;
  issuedDate?: string;
  deadline?: string;
  penaltyAmount?: number;
  gstin?: string;
  batchNumber?: string;
  manufacturerName?: string;
  sections?: Array<{ id?: string; citation?: string; title?: string; description?: string }>;
  isAiDraft?: boolean;
  pdfUrl?: string;
}

function mapNoticeType(t: string | undefined): NoticeType {
  const upper = (t || 'IMPROVEMENT').toUpperCase();
  if (upper === 'SEIZURE') return 'SEIZURE';
  if (upper === 'PANCHANAMA') return 'PANCHANAMA';
  if (upper === 'COMPOUNDED' || upper === 'COMPOUNDING') return 'COMPOUNDED';
  return 'IMPROVEMENT';
}

function mapNoticeStatus(s: string | undefined): NoticeStatus {
  const upper = (s || 'PENDING').toUpperCase();
  if (upper === 'APPROVED') return 'APPROVED';
  if (upper === 'REJECTED') return 'REJECTED';
  if (upper === 'DISPUTED') return 'DISPUTED';
  if (upper === 'PAID') return 'PAID';
  return 'PENDING';
}

function normalizeNotice(b: BackendNotice): Notice {
  return {
    id: b.id,
    caseId: b.caseId || b.id,
    // DIN number synthesized from notice ID
    dinNumber: `DIN-${b.id}`,
    type: mapNoticeType(b.type),
    businessName: b.businessName || b.manufacturerName || 'Business Entity',
    gstin: b.gstin || 'N/A',
    violatingProduct: b.productName || 'Packaged Commodity',
    sectionRefs: (b.sections || []).map((s) => s.citation || 'Rule 6').filter(Boolean),
    status: mapNoticeStatus(b.status),
    issuedDate: b.issuedDate || new Date().toISOString(),
    deadlineDate: b.deadline || new Date(Date.now() + 15 * 86400000).toISOString(),
    penaltyAmount: b.penaltyAmount || 25000,
    rewardPointsAllocated: Math.round((b.penaltyAmount || 25000) * 0.1),
    pdfUrl: b.pdfUrl,
    offenceTier: 'FIRST_OFFENCE',
  };
}

/**
 * Fetch all notices from backend.
 */
export async function fetchNoticesFromBackend(): Promise<Notice[]> {
  const items = await apiGet<BackendNotice[]>('/api/v1/notices');
  if (!Array.isArray(items)) return [];
  return items.map(normalizeNotice);
}

/**
 * Update notice status (for basic status changes).
 * For controller approval flows, use `compoundingAction` instead.
 */
export async function updateNoticeStatusOnBackend(
  id: string,
  status: string,
  comments?: string
): Promise<Notice> {
  const resp = await apiPatch<BackendNotice>(`/api/v1/notices/${id}`, {
    status: status.toLowerCase(),
    comments,
  });
  return normalizeNotice(resp);
}
