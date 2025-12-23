import type { GeoPoint } from '@/shared/types/common';

export interface Member {
  id: string;
  phoneNumber: string;
  displayName: string;
  sectorId: string;
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

export interface LoginResponse {
  tokens: AuthTokens;
  admin: AdminUser;
  sector: Sector;
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
