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
