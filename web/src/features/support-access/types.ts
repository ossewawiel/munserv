import type { AdminRole } from '@/shared/types/admin';

/**
 * Support grant statuses (see domain/support-grant.md).
 */
export const SUPPORT_GRANT_STATUSES = ['active', 'expired', 'revoked'] as const;

export type SupportGrantStatus = (typeof SUPPORT_GRANT_STATUSES)[number];

/**
 * A time-boxed grant of support access, issued by a pod chief to the super user.
 */
export interface SupportGrant {
  id: string;
  grantedRole: AdminRole;
  purpose: string;
  status: SupportGrantStatus;
  grantedBy: string;
  grantedByName: string;
  grantedAt: string;
  expiresAt: string;
  lastActivity: string | null;
  revokedAt: string | null;
  expiredAt: string | null;
}

/**
 * List response for support grants
 */
export interface SupportGrantListResponse {
  items: SupportGrant[];
  total: number;
}

/**
 * Request payload for granting support access
 */
export interface GrantSupportAccessRequest {
  grantedRole: AdminRole;
  purpose: string;
}
