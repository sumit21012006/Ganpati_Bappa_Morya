/**
 * Businesses API — wraps NestJS /api/v1/businesses endpoint.
 *
 * Schema note: backend search param is `q`, not `search`.
 */
import { apiGet } from '@/lib/apiClient';
import { Business } from '@/types';

interface BackendBusiness {
  id: string;
  name: string;
  type?: string;
  status?: string;
  ownerName?: string;
  address: string;
  location?: {
    addressLine?: string;
    city?: string;
    state?: string;
    pincode?: string;
    latitude?: number;
    longitude?: number;
  };
  gstin: string;
  turnoverBand?: string;
  geoLat?: number;
  geoLng?: number;
}

function normalizeBusinesses(items: BackendBusiness[]): Business[] {
  return items.map((b): Business => ({
    id: b.id,
    name: b.name,
    address: b.address || `${b.location?.addressLine || ''}, ${b.location?.city || ''}`.trim(),
    gstin: b.gstin,
    tradeRegNo: undefined,
    jurisdictionCircle: b.location?.city || 'Maharashtra',
    geoLat: b.geoLat || b.location?.latitude,
    geoLng: b.geoLng || b.location?.longitude,
    turnoverBand: b.turnoverBand,
  }));
}

/**
 * Search businesses by name/GSTIN/address.
 * Backend uses query param `q`.
 */
export async function searchBusinesses(query: string): Promise<Business[]> {
  const params: Record<string, string> = query.trim() ? { q: query.trim() } : {};
  const items = await apiGet<BackendBusiness[]>('/api/v1/businesses', Object.keys(params).length > 0 ? params : undefined);
  if (!Array.isArray(items)) return [];
  return normalizeBusinesses(items);
}
