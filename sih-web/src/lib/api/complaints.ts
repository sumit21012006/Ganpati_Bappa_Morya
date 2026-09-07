/**
 * Complaints API — wraps NestJS /api/v1/complaints endpoints.
 *
 * Schema notes:
 * - Backend expects `description` where frontend uses `statementOfFact`
 * - Backend returns `{ complaintId, status }` on POST, not full complaint
 * - Backend GET returns all complaints (no per-citizen filter yet)
 */
import { apiGet, apiPost } from '@/lib/apiClient';
import { Complaint, CaseStatus } from '@/types';

interface BackendComplaintResponse {
  message?: string;
  complaintId: string;
  status: string;
}

interface BackendComplaintItem {
  id: string;
  citizenId?: string;
  retailerNameText?: string;
  retailerAddressText?: string;
  category?: string;
  description?: string;
  photoUrls?: string[];
  invoiceUrl?: string;
  status?: string;
  incentiveStatus?: string;
  createdAt?: string;
}

interface SubmitComplaintDto {
  citizenId: string;
  citizenName: string;
  citizenMobile: string;
  citizenUpiVpa: string;
  retailerNameText: string;
  retailerAddressText: string;
  channel: 'OFFLINE_STORE' | 'ECOMMERCE_PLATFORM';
  category: string;
  statementOfFact: string;
  photoUrls: string[];
  invoiceUrl?: string;
}

/**
 * Map backend CaseStatus string to our typed CaseStatus.
 */
function mapCaseStatus(s: string | undefined): CaseStatus {
  const valid: CaseStatus[] = [
    'RECEIVED', 'ASSIGNED', 'INSPECTED', 'NOTICE_ISSUED',
    'COMPOUNDED', 'PROSECUTION', 'RESOLVED',
  ];
  const upper = (s || 'RECEIVED').toUpperCase() as CaseStatus;
  return valid.includes(upper) ? upper : 'RECEIVED';
}

/**
 * Submit a new citizen complaint to the NestJS backend.
 * Maps frontend field names to backend DTO.
 */
export async function submitComplaintToBackend(dto: SubmitComplaintDto): Promise<Complaint> {
  const backendBody = {
    citizenId: dto.citizenId || 'citizen_web',
    retailerNameText: dto.retailerNameText,
    retailerAddressText: dto.retailerAddressText,
    category: dto.category,
    // IMPORTANT: backend uses `description`, not `statementOfFact`
    description: dto.statementOfFact,
    photoUrls: dto.photoUrls || [],
    invoiceUrl: dto.invoiceUrl,
  };

  const resp = await apiPost<BackendComplaintResponse>('/api/v1/complaints', backendBody);

  // Backend returns minimal response — reconstruct a frontend Complaint object
  const now = new Date().toISOString();
  const complaint: Complaint = {
    id: resp.complaintId || `CMP-${Date.now()}`,
    citizenId: dto.citizenId,
    citizenName: dto.citizenName,
    citizenMobile: dto.citizenMobile,
    citizenUpiVpa: dto.citizenUpiVpa,
    retailerNameText: dto.retailerNameText,
    retailerAddressText: dto.retailerAddressText,
    channel: dto.channel,
    category: dto.category,
    statementOfFact: dto.statementOfFact,
    photoUrls: dto.photoUrls,
    invoiceUrl: dto.invoiceUrl,
    status: mapCaseStatus(resp.status),
    createdAt: now,
    updatedAt: now,
    estimatedRewardPoints: 2500,
    rewardPointsStatus: 'PENDING_COMPOUNDING',
  };

  return complaint;
}

/**
 * Fetch all complaints. Backend doesn't filter by citizen yet.
 */
export async function fetchComplaintsFromBackend(): Promise<Complaint[]> {
  const items = await apiGet<BackendComplaintItem[]>('/api/v1/complaints');

  if (!Array.isArray(items)) return [];

  return items.map((item): Complaint => {
    const now = new Date().toISOString();
    return {
      id: item.id,
      citizenId: item.citizenId || 'citizen_web',
      citizenName: 'Citizen',
      citizenMobile: '',
      citizenUpiVpa: '',
      retailerNameText: item.retailerNameText || 'Unknown Retailer',
      retailerAddressText: item.retailerAddressText || '',
      channel: 'OFFLINE_STORE',
      category: item.category || 'General Violation',
      statementOfFact: item.description || '',
      photoUrls: item.photoUrls || [],
      invoiceUrl: item.invoiceUrl,
      status: mapCaseStatus(item.status),
      createdAt: item.createdAt || now,
      updatedAt: item.createdAt || now,
      estimatedRewardPoints: 2500,
      rewardPointsStatus:
        item.incentiveStatus === 'CREDITED'
          ? 'CREDITED'
          : 'PENDING_COMPOUNDING',
    };
  });
}

/**
 * Fetch status tracker for a single complaint.
 */
export async function fetchComplaintStatus(id: string) {
  return apiGet<{
    id: string;
    status: string;
    stepper: string[];
    currentStep: number;
    incentiveStatus: string;
    retailer?: string;
  }>(`/api/v1/complaints/${id}/status`);
}
