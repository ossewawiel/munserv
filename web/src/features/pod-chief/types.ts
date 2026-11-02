/**
 * Pod Chief feature types
 * Based on backend PodDashboardDto.kt
 */

/**
 * Pod-level dashboard statistics from GET /api/v1/pod/dashboard
 */
export interface PodDashboardStats {
  /** Total number of issues in the pod */
  totalIssues: number;
  /** Number of open issues (reported, confirmed, in_progress, reopened) */
  openIssues: number;
  /** Number of issues resolved this month */
  resolvedThisMonth: number;
  /** Number of pending issues awaiting confirmation */
  pendingIssues: number;
  /** Number of active administrators in the pod */
  activeAdministrators: number;
  /** Total number of members in the pod */
  totalMembers: number;
  /** Number of active ground admins */
  activeGroundAdmins: number;
  /** Number of wards in the pod */
  wardCount: number;
  /** Number of sectors in the pod */
  sectorCount: number;
}

/**
 * Ward-level dashboard statistics from GET /api/v1/pod/dashboard/wards/{wardId}
 */
export interface WardDashboardStats {
  wardId: string;
  wardName: string;
  totalIssues: number;
  openIssues: number;
  resolvedThisMonth: number;
  sectorCount: number;
  activeGroundAdmins: number;
}

/**
 * Sector-level dashboard statistics from GET /api/v1/pod/dashboard/sectors/{sectorId}
 */
export interface SectorDashboardStats {
  sectorId: string;
  sectorName: string;
  totalIssues: number;
  openIssues: number;
  resolvedThisMonth: number;
  activeGroundAdmins: number;
  totalMembers: number;
}

// ============================================
// Pod Administrators Types
// ============================================

import type { AdminRole } from '@/shared/types/admin';

/**
 * Pod administrator entity from GET /api/v1/pod/administrators
 */
export interface PodAdministrator {
  id: string;
  email: string;
  displayName: string;
  role: AdminRole;
  level: string;
  podId: string | null;
  wardId: string | null;
  sectorId: string | null;
  createdAt: string;
  deletedAt: string | null;
}

/**
 * Response for listing pod administrators
 */
export interface PodAdministratorListResponse {
  items: PodAdministrator[];
  total: number;
}

export const POD_ADMINISTRATOR_SORT_COLUMNS = ['displayName', 'email', 'role', 'createdAt'] as const;
export type PodAdministratorSortColumn = (typeof POD_ADMINISTRATOR_SORT_COLUMNS)[number];

export interface PodAdministratorSort {
  readonly column: PodAdministratorSortColumn;
  readonly direction: 'asc' | 'desc';
}

/**
 * Query for GET /api/v1/pod/administrators; every field is optional.
 */
export interface PodAdministratorQuery {
  readonly q?: string;
  readonly roles?: readonly AdminRole[];
  readonly wardId?: string;
  readonly sort?: PodAdministratorSort;
}

/**
 * Request to create a new pod administrator
 */
export interface CreatePodAdministratorRequest {
  email: string;
  displayName: string;
  role: AdminRole;
  podId?: string;
  wardId?: string;
  sectorId?: string;
}

/**
 * Response when creating a new pod administrator (includes temporary password)
 */
export interface PodAdministratorCreatedResponse extends PodAdministrator {
  temporaryPassword: string;
}

/**
 * Request to update a pod administrator
 */
export interface UpdatePodAdministratorRequest {
  displayName?: string;
}
