/**
 * Controller API — wraps NestJS /api/v1/controller/* endpoints.
 *
 * Schema notes:
 * - Backend stats: { totalComplaints, firstOffencesCount, secondOffencesCount,
 *                    compoundedCasesCount, totalPenaltiesCollected, activeInspectors, regionCaseLoad[] }
 * - Frontend DashboardStats: { totalInspections, firstOffencesLogged, ... }
 *   → We normalize backend → frontend types.
 *
 * - Compounding action endpoint: POST /api/v1/controller/compounding/:id/action
 *   Body: { action: 'APPROVE'|'REJECT'|'PROSECUTION', comments, officerId }
 *
 * - Supply chain assign: PATCH /api/v1/controller/supply-chain-links/:id/assign
 *   Body: { inspectorId }
 */
import { apiGet, apiPost, apiPatch } from '@/lib/apiClient';
import { DashboardStats } from '@/types';

interface BackendDashboardStats {
  totalComplaints?: number;
  firstOffencesCount?: number;
  secondOffencesCount?: number;
  compoundedCasesCount?: number;
  totalPenaltiesCollected?: number;
  activeInspectors?: number;
  activeOfficersCount?: number;
  regionCaseLoad?: Array<{
    region: string;
    activeCases?: number;
    resolvedCases?: number;
  }>;
  // In case backend already returns frontend-shaped data
  totalInspections?: number;
  firstOffencesLogged?: number;
  secondOffencesLogged?: number;
  penaltiesRecoveredRupees?: string;
  regionalRadar?: any[];
}

interface BackendCompoundingActionResponse {
  noticeId: string;
  actionTaken: string;
  newState: string;
  comments?: string;
  timestamp: string;
}

interface BackendSupplyChainAssignResponse {
  id: string;
  status: string;
  assignedInspectorId?: string;
}

/**
 * Normalize backend dashboard stats → frontend DashboardStats shape.
 */
function normalizeDashboardStats(b: BackendDashboardStats): DashboardStats {
  // If backend already returns the frontend-shaped response with regionalRadar, use it directly
  if (b.totalInspections !== undefined && (b as any).regionalRadar !== undefined) {
    return b as unknown as DashboardStats;
  }

  // Normalize from backend schema
  const penaltyCr =
    typeof b.totalPenaltiesCollected === 'number'
      ? `₹${(b.totalPenaltiesCollected / 10000000).toFixed(2)} Cr`
      : '₹0.00 Cr';

  const regionalRadar = (b.regionCaseLoad || []).map((r) => ({
    region: r.region,
    alertLevel:
      (r.activeCases || 0) > 30
        ? ('High Alert' as const)
        : (r.activeCases || 0) > 15
          ? ('Moderate Watch' as const)
          : ('Compliant' as const),
    inspections: (r.activeCases || 0) + (r.resolvedCases || 0),
    violations: r.activeCases || 0,
    recoveryRupees: `${Math.round(((r.resolvedCases || 0) * 25000) / 100000)} L`,
    slaRatePercent: (r.resolvedCases || 0) + (r.activeCases || 0) > 0
      ? Math.round(
          ((r.resolvedCases || 0) /
            ((r.activeCases || 0) + (r.resolvedCases || 0))) *
            100
        )
      : 0,
  }));

  const totalInspections = b.totalInspections ?? b.totalComplaints ?? 0;
  const firstOffences = b.firstOffencesCount ?? b.firstOffencesLogged ?? 0;
  const secondOffences = b.secondOffencesCount ?? b.secondOffencesLogged ?? 0;

  return {
    totalInspections,
    totalInspectionsTarget: (b as any).totalInspectionsTarget ?? Math.round(totalInspections * 1.2),
    firstOffencesLogged: firstOffences,
    firstOffencesNoticesServed: (b as any).firstOffencesNoticesServed ?? Math.round(firstOffences * 0.8),
    firstOffencesUnderVerification: (b as any).firstOffencesUnderVerification ?? Math.round(firstOffences * 0.2),
    secondOffencesLogged: secondOffences,
    secondOffencesChargesheets: (b as any).secondOffencesChargesheets ?? Math.round(secondOffences * 0.9),
    secondOffencesSeizuresPending: (b as any).secondOffencesSeizuresPending ?? Math.round(secondOffences * 0.1),
    penaltiesRecoveredRupees: penaltyCr,
    citizenRewardsPaidPoints: (b as any).citizenRewardsPaidPoints ?? ((b.compoundedCasesCount || 0) * 5000),
    activeOfficersCount: b.activeInspectors || b.activeOfficersCount || 0,
    regionalRadar,
  };
}

/**
 * Fetch controller dashboard statistics.
 */
export async function fetchDashboardStatsFromBackend(): Promise<DashboardStats> {
  const resp = await apiGet<BackendDashboardStats>(
    '/api/v1/controller/dashboard/stats'
  );
  return normalizeDashboardStats(resp);
}

/**
 * Controller: Approve, Reject, or Escalate a compounding order.
 * Correct endpoint: POST /api/v1/controller/compounding/:id/action
 */
export async function compoundingAction(
  noticeId: string,
  action: 'APPROVE' | 'REJECT' | 'PROSECUTION',
  comments?: string,
  officerId?: string
): Promise<BackendCompoundingActionResponse> {
  return apiPost<BackendCompoundingActionResponse>(
    `/api/v1/controller/compounding/${noticeId}/action`,
    {
      action,
      comments: comments || '',
      officerId: officerId || 'ctrl_001',
    }
  );
}

/**
 * Controller: Assign supply-chain link to inspector.
 */
export async function assignSupplyChainLink(
  linkId: string,
  inspectorId: string
): Promise<BackendSupplyChainAssignResponse> {
  return apiPatch<BackendSupplyChainAssignResponse>(
    `/api/v1/controller/supply-chain-links/${linkId}/assign`,
    { inspectorId }
  );
}

/**
 * Controller: Fetch upstream supply chain contraband links.
 */
export async function fetchSupplyChainLinks(): Promise<import('@/types').SupplyChainLink[]> {
  const items = await apiGet<import('@/types').SupplyChainLink[]>(
    '/api/v1/controller/supply-chain-links'
  );
  return Array.isArray(items) ? items : [];
}


export interface InspectorOption {
  id: string;
  name: string;
  email: string;
  phone: string;
  district: string;
  jurisdiction: string;
}

/**
 * Controller: Fetch active field inspectors with jurisdictions for raid assignment.
 */
export async function fetchInspectors(): Promise<InspectorOption[]> {
  try {
    const items = await apiGet<InspectorOption[]>('/api/v1/controller/inspectors');
    return Array.isArray(items) ? items : [];
  } catch {
    return [];
  }
}
