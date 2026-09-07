/**
 * Centralized HTTP API client for sih-web → NestJS backend.
 *
 * Usage:
 *   import { apiGet, apiPost, apiPatch } from '@/lib/apiClient';
 *   const data = await apiGet('/api/v1/controller/dashboard/stats');
 */

const BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

function getAuthToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('sih_auth_token');
}

function buildHeaders(extra: Record<string, string> = {}): HeadersInit {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...extra,
  };
  const token = getAuthToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public body: unknown,
    message: string
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let body: unknown = null;
    try {
      body = await res.json();
    } catch {
      body = await res.text();
    }
    const msg =
      typeof body === 'object' && body !== null && 'error' in (body as object)
        ? String((body as Record<string, unknown>).error)
        : `HTTP ${res.status} ${res.statusText}`;
    throw new ApiError(res.status, body, msg);
  }
  // 204 No Content
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export async function apiGet<T = unknown>(path: string, params?: Record<string, string>): Promise<T> {
  let url = `${BASE_URL}${path}`;
  if (params && Object.keys(params).length > 0) {
    url += '?' + new URLSearchParams(params).toString();
  }
  const res = await fetch(url, {
    method: 'GET',
    headers: buildHeaders(),
  });
  return handleResponse<T>(res);
}

export async function apiPost<T = unknown>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers: buildHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse<T>(res);
}

export async function apiPatch<T = unknown>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'PATCH',
    headers: buildHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse<T>(res);
}

export function storeAuthToken(token: string) {
  if (typeof window !== 'undefined') {
    localStorage.setItem('sih_auth_token', token);
  }
}

export function clearAuthToken() {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('sih_auth_token');
  }
}
