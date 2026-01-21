import { apiClient } from '@/lib/api-client';
import type {
  GroundAdmin,
  GroundAdminListResponse,
  GroundAdminStatus,
  InviteGroundAdminResponse,
  GroundAdminActionResponse,
} from '@/shared/types/groundAdmin';

export const groundAdminApi = {
  /**
   * List Ground Admins in a sector
   */
  listInSector: (sectorId: string, status?: GroundAdminStatus) =>
    apiClient
      .get<GroundAdminListResponse>(`/sectors/${sectorId}/ground-admins`, {
        params: status ? { status } : undefined,
      })
      .then((r) => r.data),

  /**
   * Invite a member to become Ground Admin (Admin only)
   */
  invite: (memberId: string, message?: string) =>
    apiClient
      .post<InviteGroundAdminResponse>(
        `/members/${memberId}/ground-admin/invite`,
        { message }
      )
      .then((r) => r.data),

  /**
   * Approve Ground Admin application (Admin only)
   */
  approve: (memberId: string, applicationId: string) =>
    apiClient
      .post<GroundAdminActionResponse>(
        `/members/${memberId}/ground-admin/approve`,
        { applicationId }
      )
      .then((r) => r.data),

  /**
   * Decline Ground Admin application (Admin only)
   */
  decline: (memberId: string, applicationId: string, reason: string) =>
    apiClient
      .post<GroundAdminActionResponse>(
        `/members/${memberId}/ground-admin/decline`,
        { applicationId, reason }
      )
      .then((r) => r.data),

  /**
   * Revoke Ground Admin status (Admin only)
   */
  revoke: (memberId: string, reason: string) =>
    apiClient
      .post<GroundAdminActionResponse>(
        `/members/${memberId}/ground-admin/revoke`,
        { reason }
      )
      .then((r) => r.data),

  /**
   * Update Ground Admin status (Admin only)
   */
  updateStatus: (memberId: string, status: 'active' | 'on_hold') =>
    apiClient
      .patch<GroundAdmin>(`/members/${memberId}/ground-admin/status`, {
        status,
      })
      .then((r) => r.data),

  /**
   * Revoke a pending Ground Admin invitation (Admin only)
   */
  revokeInvite: (memberId: string, applicationId: string) =>
    apiClient
      .delete<{ status: string }>(
        `/members/${memberId}/ground-admin/invite/${applicationId}`
      )
      .then((r) => r.data),
};
