/**
 * Admin roles in the system, ordered by permission level (lowest to highest)
 * 6-level hierarchy: sector_admin < sector_chief < ward_admin < ward_chief < pod_admin < pod_chief
 */
export const ADMIN_ROLES = [
  'sector_admin',
  'sector_chief',
  'ward_admin',
  'ward_chief',
  'pod_admin',
  'pod_chief',
] as const;

export type AdminRole = (typeof ADMIN_ROLES)[number];

/**
 * Organizational levels for admin roles
 */
export type AdminLevel = 'sector' | 'ward' | 'pod';

/**
 * Role hierarchy - higher index means more permissions
 */
export const ROLE_HIERARCHY: Record<AdminRole, number> = {
  sector_admin: 0,
  sector_chief: 1,
  ward_admin: 2,
  ward_chief: 3,
  pod_admin: 4,
  pod_chief: 5,
};

/**
 * Mapping from role to organizational level
 */
export const ROLE_LEVEL: Record<AdminRole, AdminLevel> = {
  sector_admin: 'sector',
  sector_chief: 'sector',
  ward_admin: 'ward',
  ward_chief: 'ward',
  pod_admin: 'pod',
  pod_chief: 'pod',
};

/**
 * Check if a user with the given role has at least the required permission level
 */
export function hasPermission(userRole: AdminRole, requiredRole: AdminRole): boolean {
  return ROLE_HIERARCHY[userRole] >= ROLE_HIERARCHY[requiredRole];
}

/**
 * Check if a user can manage (create/edit/delete) another role
 * Users can only manage roles strictly lower than their own
 */
export function canManageRole(userRole: AdminRole, targetRole: AdminRole): boolean {
  return ROLE_HIERARCHY[userRole] > ROLE_HIERARCHY[targetRole];
}

/**
 * Get the organizational level for a role
 */
export function getRoleLevel(role: AdminRole): AdminLevel {
  return ROLE_LEVEL[role];
}

/**
 * Check if a role is a chief (supervisor) role at its level
 */
export function isChiefRole(role: AdminRole): boolean {
  return role === 'sector_chief' || role === 'ward_chief' || role === 'pod_chief';
}

/**
 * Get roles that a user can manage based on their role
 * Returns all roles strictly lower than the user's role
 */
export function getManageableRoles(userRole: AdminRole): AdminRole[] {
  const userLevel = ROLE_HIERARCHY[userRole];
  return ADMIN_ROLES.filter((role) => ROLE_HIERARCHY[role] < userLevel);
}

/**
 * Get display label for a role
 */
export const ADMIN_ROLE_LABELS: Record<AdminRole, string> = {
  sector_admin: 'Sector Admin',
  sector_chief: 'Sector Chief',
  ward_admin: 'Ward Admin',
  ward_chief: 'Ward Chief',
  pod_admin: 'Pod Admin',
  pod_chief: 'Pod Chief',
};

/**
 * Convert backend role format (uppercase) to frontend format (lowercase with underscore)
 */
export function normalizeRole(role: string): AdminRole {
  const normalized = role.toLowerCase().replace('-', '_');
  if (ADMIN_ROLES.includes(normalized as AdminRole)) {
    return normalized as AdminRole;
  }
  // Default to lowest permission if unknown
  return 'sector_admin';
}
