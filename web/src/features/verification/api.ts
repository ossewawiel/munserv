import { apiClient } from '@/lib/api-client';
import type {
  IssueVerification,
  RequestVerificationRequest,
  VerificationHistoryResponse,
} from '@/shared/types/verification';

export const verificationApi = {
  /**
   * Request Ground Admin verification for an issue (Admin only)
   */
  requestVerification: (issueId: string, request: RequestVerificationRequest) =>
    apiClient
      .post<IssueVerification>(`/issues/${issueId}/request-verification`, request)
      .then((r) => r.data),

  /**
   * Get verification history for an issue
   */
  getHistory: (issueId: string) =>
    apiClient
      .get<VerificationHistoryResponse>(`/issues/${issueId}/verifications`)
      .then((r) => r.data),
};
