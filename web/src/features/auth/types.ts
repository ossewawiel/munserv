import type { GeoPoint } from '@/shared/types/common';
import type { AdminRole, UserRole } from '@/shared/types/admin';

/**
 * Member status for registration workflow
 * MVP: always 'active'. Phase 2: 'pending_approval' until admin approves
 */
export type MemberStatus = 'active' | 'pending_approval' | 'suspended';

export const MEMBER_STATUS_LABELS: Record<MemberStatus, string> = {
  active: 'Active',
  pending_approval: 'Pending Approval',
  suspended: 'Suspended',
};

export interface Member {
  id: string;
  firstName: string;
  surname: string;
  phoneNumber: string;
  address: string;
  registrationLocation: GeoPoint;
  sectorId: string;
  status: MemberStatus;
  createdAt: string;
}

export interface Sector {
  id: string;
  name: string;
  center: GeoPoint;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
}

export interface MemberProfile {
  member: Member;
  sector: Sector;
}

export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  sectorId: string | null;
  role: UserRole;
  level?: string;
  podId?: string | null;
  wardId?: string | null;
  onboardingStatus?: string | null;
}

export interface LoginRequest {
  email: string;
  password: string;
}

/**
 * A support grant carried on a login response when the super user signs in
 * while a support grant is active (see domain/support-grant.md).
 */
export interface SupportGrantInfo {
  grantId: string;
  grantedRole: AdminRole;
  expiresAt: string;
}

export interface AdminProfile {
  admin: AdminUser;
  sector: Sector | null;
  bootstrapStatus?: string;
  supportGrant?: SupportGrantInfo | null;
}

/**
 * Response from GET /support-access/grants/current. The endpoint returns the
 * full grant; this story only consumes the slid `expiresAt`.
 */
export interface CurrentSupportGrantResponse {
  expiresAt: string;
}

export interface LoginResponse {
  tokens: AuthTokens;
  profile: AdminProfile;
}

/**
 * Refresh token request
 */
export interface RefreshTokenRequest {
  refreshToken: string;
}

/**
 * Auth state for the application
 */
export interface AuthState {
  admin: AdminUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

// Re-export for backward compatibility
export { ADMIN_ROLE_LABELS } from '@/shared/types/admin';

/**
 * Web registration request payload
 */
export interface RegisterRequest {
  email: string;
  firstName: string;
  surname: string;
  phone: string;
  address: string;
  latitude: number;
  longitude: number;
  sectorId: string;
}

/**
 * Web registration response
 */
export interface RegisterResponse {
  message: string;
  memberId: string;
}
