/**
 * Admin roles in the system, ordered by permission level (lowest to highest)
 */
export const ADMIN_ROLES = [
  'sector_admin',
  'sector_chief',
  'pod_admin',
  'pod_chief',
] as const;

export type AdminRole = (typeof ADMIN_ROLES)[number];

/**
 * Role hierarchy - higher index means more permissions
 */
const ROLE_HIERARCHY: Record<AdminRole, number> = {
  sector_admin: 0,
  sector_chief: 1,
  pod_admin: 2,
  pod_chief: 3,
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
 * Get display label for a role
 */
export const ADMIN_ROLE_LABELS: Record<AdminRole, string> = {
  sector_admin: 'Sector Admin',
  sector_chief: 'Sector Chief',
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
