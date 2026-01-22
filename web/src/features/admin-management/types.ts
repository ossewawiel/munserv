import type { AdminRole } from '@/shared/types/admin';

/**
 * Admin entity as returned by the API
 */
export interface Admin {
  id: string;
  email: string;
  displayName: string;
  role: AdminRole;
  sectorId: string;
  createdAt: string;
  deletedAt: string | null;
}

/**
 * Request payload for creating a new admin
 */
export interface CreateAdminRequest {
  email: string;
  displayName: string;
  role: AdminRole;
}

/**
 * Response when creating a new admin (includes temporary password)
 */
export interface AdminCreatedResponse extends Admin {
  temporaryPassword: string;
}

/**
 * Request payload for updating an admin
 */
export interface UpdateAdminRequest {
  displayName?: string;
}

/**
 * List response for admins
 */
export interface AdminListResponse {
  items: Admin[];
  total: number;
}
