import { apiClient } from '@/lib/api-client';
import type { LoginRequest, LoginResponse, Sector } from './types';

export const authApi = {
  login: (data: LoginRequest) =>
    apiClient.post<LoginResponse>('/auth/admin/login', data).then((r) => r.data),

  logout: () => apiClient.post('/auth/logout'),

  getSectors: () =>
    apiClient.get<{ items: Sector[] }>('/sectors').then((r) => r.data.items),
};
