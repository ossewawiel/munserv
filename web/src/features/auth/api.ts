import { apiClient } from '@/lib/api-client';
import type { LoginRequest, LoginResponse, RegisterRequest, RegisterResponse, Sector } from './types';

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
};
