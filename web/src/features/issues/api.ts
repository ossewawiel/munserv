import { apiClient } from '@/lib/api-client';
import type { PaginatedResponse } from '@/shared/types/common';
import type { Issue, IssueSummary, IssueFilterParams, UpdateIssueStateRequest } from './types';

export const issueApi = {
  getAll: (params?: IssueFilterParams) =>
    apiClient
      .get<PaginatedResponse<IssueSummary>>('/issues', { params })
      .then((r) => r.data),

  getById: (id: string) =>
    apiClient.get<Issue>(`/issues/${id}`).then((r) => r.data),

  getMine: (params?: { page?: number; limit?: number }) =>
    apiClient
      .get<PaginatedResponse<IssueSummary>>('/issues/mine', { params })
      .then((r) => r.data),

  updateState: (id: string, data: UpdateIssueStateRequest) =>
    apiClient.patch<Issue>(`/issues/${id}/state`, data).then((r) => r.data),
};
