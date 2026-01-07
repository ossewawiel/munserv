import { apiClient } from '@/lib/api-client';
import type { PaginatedResponse } from '@/shared/types/common';
import type { MemberListItem } from './types';

export const membersApi = {
  getAll: (sectorId: string, params?: { page?: number; limit?: number }) =>
    apiClient
      .get<PaginatedResponse<MemberListItem>>('/admin/members', {
        params: { sectorId, ...params },
      })
      .then((r) => r.data),
};
