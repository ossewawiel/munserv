import { apiClient } from '@/lib/api-client';
import type { PaginatedResponse } from '@/shared/types/common';
import type { MemberStatus } from '@/features/auth/types';
import type { MemberListItem, MemberApproveResponse } from './types';

export const membersApi = {
  getAll: (
    sectorId: string,
    params?: { page?: number; limit?: number; status?: MemberStatus }
  ) =>
    apiClient
      .get<PaginatedResponse<MemberListItem>>('/admin/members', {
        params: { sectorId, ...params },
      })
      .then((r) => r.data),

  approve: (id: string) =>
    apiClient
      .post<MemberApproveResponse>(`/admin/members/${id}/approve`)
      .then((r) => r.data),

  reject: (id: string) => apiClient.delete(`/admin/members/${id}`),

  getPendingCount: (sectorId: string) =>
    apiClient
      .get<{ count: number }>('/admin/members/pending-count', {
        params: { sectorId },
      })
      .then((r) => r.data.count),
};
