import type { MemberStatus } from '@/features/auth/types';

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
}

/**
 * Response from member approval
 */
export interface MemberApproveResponse {
  memberId: string;
  email: string;
  message: string;
}
