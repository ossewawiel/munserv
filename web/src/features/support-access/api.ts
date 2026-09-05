import { apiClient } from '@/lib/api-client';
import type {
  GrantSupportAccessRequest,
  SupportGrant,
  SupportGrantListResponse,
  SupportGrantStatus,
} from './types';

export const supportAccessApi = {
  /**
   * List support grants, optionally filtered by status
   */
  list: (status?: SupportGrantStatus) =>
    apiClient
      .get<SupportGrantListResponse>('/support-access/grants', {
        params: status ? { status } : undefined,
      })
      .then((r) => r.data),

  /**
   * Grant support access to the super user
   */
  grant: (request: GrantSupportAccessRequest) =>
    apiClient.post<SupportGrant>('/support-access/grants', request).then((r) => r.data),
};
