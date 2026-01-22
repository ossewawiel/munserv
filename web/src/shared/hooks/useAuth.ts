import { useCallback, useMemo } from 'react';
import type { AdminUser } from '@/features/auth/types';
import {
  hasPermission as checkPermission,
  normalizeRole,
  type AdminRole,
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
      // Normalize role from backend format to frontend format
      return {
        ...parsed,
        role: normalizeRole(parsed.role as string),
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
   * Check if the current admin has at least the required permission level
   */
  const hasPermission = useCallback(
    (requiredRole: AdminRole): boolean => {
      if (!admin) return false;
      return checkPermission(admin.role, requiredRole);
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
