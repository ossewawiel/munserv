import { useCallback, useMemo } from 'react';
import type { AdminUser } from '@/features/auth/types';
import {
  hasPermission as checkPermission,
  normalizeRole,
  isAdminRole,
  SUPER_USER_ROLE,
  type AdminRole,
  type UserRole,
} from '@/shared/types/admin';

const ACCESS_TOKEN_KEY = 'accessToken';
const REFRESH_TOKEN_KEY = 'refreshToken';
const ADMIN_KEY = 'admin';

export function useAuth() {
  const getStoredAdmin = useCallback((): AdminUser | null => {
    const stored = localStorage.getItem(ADMIN_KEY);
    if (!stored) return null;
    try {
      const parsed = JSON.parse(stored) as AdminUser;
      const roleStr = parsed.role as string;
      // Keep SUPER_USER as-is, normalize other roles
      const normalizedRole: UserRole =
        roleStr === SUPER_USER_ROLE ? SUPER_USER_ROLE : normalizeRole(roleStr);
      return {
        ...parsed,
        role: normalizedRole,
      };
    } catch {
      return null;
    }
  }, []);

  const isAuthenticated = useMemo(() => {
    return !!localStorage.getItem(ACCESS_TOKEN_KEY);
  }, []);

  const admin = useMemo(() => getStoredAdmin(), [getStoredAdmin]);

  const login = useCallback((tokens: { accessToken: string; refreshToken: string }, adminData: AdminUser) => {
    localStorage.setItem(ACCESS_TOKEN_KEY, tokens.accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, tokens.refreshToken);
    localStorage.setItem(ADMIN_KEY, JSON.stringify(adminData));
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(ADMIN_KEY);
  }, []);

  /**
   * Check if the current admin has at least the required permission level.
   * Super users always have all permissions.
   */
  const hasPermission = useCallback(
    (requiredRole: AdminRole): boolean => {
      if (!admin) return false;
      // Super user has all permissions
      if (admin.role === SUPER_USER_ROLE) return true;
      // Regular admin - check role hierarchy
      if (isAdminRole(admin.role)) {
        return checkPermission(admin.role, requiredRole);
      }
      return false;
    },
    [admin]
  );

  return {
    isAuthenticated,
    admin,
    login,
    logout,
    hasPermission,
  };
}
