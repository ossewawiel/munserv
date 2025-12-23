import { useCallback, useMemo } from 'react';
import type { AdminUser } from '@/features/auth/types';

const ACCESS_TOKEN_KEY = 'accessToken';
const REFRESH_TOKEN_KEY = 'refreshToken';
const ADMIN_KEY = 'admin';

export function useAuth() {
  const getStoredAdmin = useCallback((): AdminUser | null => {
    const stored = localStorage.getItem(ADMIN_KEY);
    if (!stored) return null;
    try {
      return JSON.parse(stored) as AdminUser;
    } catch {
      return null;
    }
  }, []);

  const isAuthenticated = useMemo(() => {
    return !!localStorage.getItem(ACCESS_TOKEN_KEY);
  }, []);

  const admin = useMemo(() => getStoredAdmin(), [getStoredAdmin]);

  const login = useCallback((tokens: { accessToken: string; refreshToken: string }, admin: AdminUser) => {
    localStorage.setItem(ACCESS_TOKEN_KEY, tokens.accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, tokens.refreshToken);
    localStorage.setItem(ADMIN_KEY, JSON.stringify(admin));
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(ADMIN_KEY);
  }, []);

  return {
    isAuthenticated,
    admin,
    login,
    logout,
  };
}
