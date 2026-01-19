/**
 * Status of a Ground Admin
 */
export type GroundAdminStatus = 'active' | 'on_hold' | 'inactive';

/**
 * Ground Admin information
 */
export interface GroundAdmin {
  id: string;
  memberId: string;
  name: string;
  status: GroundAdminStatus;
  since: string;
  responseRate: number;
  pendingVerifications: number;
}

/**
 * Ground Admin list response
 */
export interface GroundAdminListResponse {
  items: GroundAdmin[];
  total: number;
}

/**
 * Ground Admin application or invitation
 */
export interface GroundAdminApplication {
  id: string;
  memberId: string;
  memberName: string;
  type: 'application' | 'invitation';
  status: string;
  createdAt: string;
}

/**
 * Response when inviting a member to become Ground Admin
 */
export interface InviteGroundAdminResponse {
  applicationId: string;
  status: string;
}

/**
 * Response when approving/declining Ground Admin application
 */
export interface GroundAdminActionResponse {
  status: string;
  member?: {
    id: string;
    name: string;
    isGroundAdmin: boolean;
    groundAdminStatus?: GroundAdminStatus;
  };
}

/**
 * Map Ground Admin status to i18n label keys
 */
export const GROUND_ADMIN_STATUS_LABELS: Record<GroundAdminStatus, string> = {
  active: 'groundAdmin.status.active',
  on_hold: 'groundAdmin.status.onHold',
  inactive: 'groundAdmin.status.inactive',
};

/**
 * Ground Admin statuses as array for filters
 */
export const GROUND_ADMIN_STATUSES: GroundAdminStatus[] = [
  'active',
  'on_hold',
  'inactive',
];
