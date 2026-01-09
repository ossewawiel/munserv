import type { GeoPoint } from '@/shared/types/common';

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
  sectorId: string;
  role: 'SECTOR_ADMIN' | 'COMMUNITY_ADMIN';
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AdminProfile {
  admin: AdminUser;
  sector: Sector;
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

export const ADMIN_ROLE_LABELS: Record<AdminUser['role'], string> = {
  SECTOR_ADMIN: 'Sector Admin',
  COMMUNITY_ADMIN: 'Community Admin',
};

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
