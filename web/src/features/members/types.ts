import type { MemberStatus } from '@/features/auth/types';
import type { GroundAdminStatus } from '@/shared/types/groundAdmin';

/**
 * Member summary for admin list views
 */
export interface MemberListItem {
  id: string;
  firstName: string;
  surname: string;
  email: string;
  phoneNumber: string;
  address: string;
  status: MemberStatus;
  issueCount: number;
  joinedAt: string;
  /** Whether member is currently a Ground Admin */
  isGroundAdmin: boolean;
  /** Ground Admin status (only present if isGroundAdmin is true) */
  groundAdminStatus?: GroundAdminStatus;
  /** Whether member has a pending Ground Admin application */
  hasPendingApplication?: boolean;
  /** Whether member has a pending Ground Admin invitation */
  hasInvitationPending?: boolean;
  /** Application/invitation ID if pending (needed for revoke action) */
  pendingApplicationId?: string;
}

/**
 * Full member entity (re-exported from auth for convenience)
 */
export type { Member } from '@/features/auth/types';

/**
 * Member filter parameters
 */
export interface MemberFilterParams {
  sectorId?: string;
  search?: string;
  status?: MemberStatus;
  page?: number;
  limit?: number;
  /** Filter to only Ground Admins */
  isGroundAdmin?: boolean;
  /** Filter to members with pending GA applications */
  hasPendingApplication?: boolean;
  /** Filter to members with pending GA invitations */
  hasInvitationPending?: boolean;
}

/**
 * Response from member approval
 */
export interface MemberApproveResponse {
  memberId: string;
  email: string;
  message: string;
}
