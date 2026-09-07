/**
 * Auth API — wraps NestJS /api/v1/auth/* endpoints.
 */
import { apiGet, apiPost, storeAuthToken } from '@/lib/apiClient';
import { UserRole, AuthUser } from '@/types';


interface BackendLoginResponse {
  user: {
    id: string;
    name: string;
    email: string;
    phone?: string;
    role: string;
    designation?: string;
    badgeId?: string;
    businessId?: string;
    isInspector?: boolean;
    isBusiness?: boolean;
    keycloakId?: string;
  };
  tokens?: {
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
  };
  accessToken?: string;
}

/**
 * Maps the NestJS role string to our frontend UserRole type.
 * Backend may return 'INSPECTOR', 'BUSINESS', 'CITIZEN', 'CONTROLLER'.
 */
function mapRole(backendRole: string, requestedRole: UserRole): UserRole {
  const upper = (backendRole || '').toUpperCase();
  if (upper === 'CONTROLLER') return 'CONTROLLER';
  if (upper === 'INSPECTOR') return 'INSPECTOR';
  if (upper === 'BUSINESS') return 'BUSINESS';
  // Default to the role the user selected on login
  return requestedRole;
}

/**
 * Login via NestJS backend.
 * Returns a normalized AuthUser and stores the JWT token.
 */
export async function loginToBackend(
  identifier: string,
  password: string,
  role: UserRole
): Promise<AuthUser> {
  // NestJS auth/login expects: { username, password } or { phone, password }
  const body: Record<string, string> = {
    username: identifier,
    password,
    role,
  };

  const resp = await apiPost<BackendLoginResponse>('/api/v1/auth/login', body);

  // Store JWT for subsequent API calls
  const token = resp.tokens?.accessToken || resp.accessToken || '';
  if (token) storeAuthToken(token);

  const backendUser = resp.user;
  const mappedRole = mapRole(backendUser.role, role);

  const authUser: AuthUser = {
    id: backendUser.id,
    name: backendUser.name,
    email: backendUser.email || identifier,
    mobile: backendUser.phone,
    badgeId: backendUser.badgeId,
    role: mappedRole,
    rewardPoints: 0,
    createdAt: new Date().toISOString(),
  };

  return authUser;
}

/**
 * Register via NestJS backend.
 */
export async function registerToBackend(data: {
  name: string;
  email: string;
  mobile?: string;
  password: string;
  role: UserRole;
  upiVpa?: string;
  badgeId?: string;
}): Promise<AuthUser> {
  const body = {
    username: data.email,
    email: data.email,
    phone: data.mobile,
    password: data.password,
    role: data.role,
    fullName: data.name,
  };

  const resp = await apiPost<BackendLoginResponse>('/api/v1/auth/register', body);

  const token = resp.tokens?.accessToken || resp.accessToken || '';
  if (token) storeAuthToken(token);

  const backendUser = resp.user;

  const authUser: AuthUser = {
    id: backendUser.id || `usr_${Date.now()}`,
    name: backendUser.name || data.name,
    email: backendUser.email || data.email,
    mobile: data.mobile,
    badgeId: data.badgeId,
    role: data.role,
    rewardPoints: data.role === 'CITIZEN' ? 500 : 0,
    upiVpa: data.upiVpa,
    createdAt: new Date().toISOString(),
  };

  return authUser;
}

/**
 * Revalidate stored session against GET /api/v1/auth/me
 */
export async function getAuthMe(): Promise<AuthUser> {
  const resp = await apiGet<{
    id: string;
    name: string;
    email: string;
    phone?: string;
    role: string;
    designation?: string;
    badgeId?: string;
    jurisdiction?: string;
  }>('/api/v1/auth/me');

  const upperRole = (resp.role || '').toUpperCase();
  const mappedRole: UserRole =
    upperRole === 'CONTROLLER' ? 'CONTROLLER' :
    upperRole === 'INSPECTOR' ? 'INSPECTOR' :
    upperRole === 'BUSINESS' ? 'BUSINESS' : 'CITIZEN';

  return {
    id: resp.id,
    name: resp.name,
    email: resp.email,
    mobile: resp.phone,
    badgeId: resp.badgeId,
    role: mappedRole,
    rewardPoints: mappedRole === 'CITIZEN' ? 2750 : 0,
    createdAt: new Date().toISOString(),
  };
}

