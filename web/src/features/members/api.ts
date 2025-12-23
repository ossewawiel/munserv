import { apiClient } from '@/lib/api-client';
import type { PaginatedResponse } from '@/shared/types/common';
import type { MemberListItem } from './types';

export const membersApi = {
  getAll: (params?: { page?: number; limit?: number }) =>
    apiClient
      .get<PaginatedResponse<MemberListItem>>('/admin/members', { params })
      .then((r) => r.data),
};
