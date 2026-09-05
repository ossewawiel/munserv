import { apiClient } from '@/lib/api-client';
import type {
  CurrentSupportGrantResponse,
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  Sector,
} from './types';

export const authApi = {
  login: (data: LoginRequest) =>
    apiClient.post<LoginResponse>('/auth/admin/login', data).then((r) => r.data),

  logout: () => apiClient.post('/auth/logout'),

  getSectors: () =>
    apiClient.get<{ items: Sector[] }>('/sectors').then((r) => r.data.items),

  /**
   * Register a new member via web form
   */
  registerMember: (data: RegisterRequest) =>
    apiClient.post<RegisterResponse>('/auth/register/web', data).then((r) => r.data),

  /**
   * The caller's own support grant, with its server-slid `expiresAt`.
   * Grant-scoped tokens only; call this only when a support grant is stored.
   */
  getCurrentSupportGrant: () =>
    apiClient
      .get<CurrentSupportGrantResponse>('/support-access/grants/current')
      .then((r) => r.data),
};
