import { apiClient } from '@/lib/api-client';
import type { PaginatedResponse } from '@/shared/types/common';
import type { MemberListItem, MemberApproveResponse, MemberFilterParams } from './types';

export const membersApi = {
  getAll: (sectorId: string, params: MemberFilterParams = {}) => {
    const queryParams: Record<string, string | number | boolean> = { sectorId };

    if (params.page) queryParams.page = params.page;
    if (params.limit) queryParams.limit = params.limit;
    if (params.status) queryParams.status = params.status;
    if (params.search) queryParams.search = params.search;
    if (params.isGroundAdmin !== undefined)
      queryParams.isGroundAdmin = params.isGroundAdmin;
    if (params.hasPendingApplication !== undefined)
      queryParams.hasPendingApplication = params.hasPendingApplication;
    if (params.hasInvitationPending !== undefined)
      queryParams.hasInvitationPending = params.hasInvitationPending;

    return apiClient
      .get<PaginatedResponse<MemberListItem>>('/admin/members', {
        params: queryParams,
      })
      .then((r) => r.data);
  },

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
