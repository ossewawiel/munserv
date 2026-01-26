import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { authApi } from './api';
import type { LoginRequest, RegisterRequest } from './types';

const ACCESS_TOKEN_KEY = 'accessToken';
const REFRESH_TOKEN_KEY = 'refreshToken';
const ADMIN_KEY = 'admin';
const IS_SUPER_USER_KEY = 'isSuperUser';

export function useLogin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: LoginRequest) => authApi.login(data),
    onSuccess: (response) => {
      // Store tokens and admin in localStorage
      localStorage.setItem(ACCESS_TOKEN_KEY, response.tokens.accessToken);
      localStorage.setItem(REFRESH_TOKEN_KEY, response.tokens.refreshToken);
      localStorage.setItem(ADMIN_KEY, JSON.stringify(response.profile.admin));

      // Track super user session
      if (response.profile.admin.role === 'SUPER_USER') {
        localStorage.setItem(IS_SUPER_USER_KEY, 'true');
      } else {
        localStorage.removeItem(IS_SUPER_USER_KEY);
      }

      // Also update React Query cache
      queryClient.setQueryData(['auth', 'admin'], response.profile.admin);
    },
  });
}

export function useLogout() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => authApi.logout(),
    onSuccess: () => {
      // Clear localStorage
      localStorage.removeItem(ACCESS_TOKEN_KEY);
      localStorage.removeItem(REFRESH_TOKEN_KEY);
      localStorage.removeItem(ADMIN_KEY);
      localStorage.removeItem(IS_SUPER_USER_KEY);
      // Clear React Query cache
      queryClient.clear();
    },
  });
}

export function useSectors() {
  return useQuery({
    queryKey: ['sectors'],
    queryFn: () => authApi.getSectors(),
    staleTime: 1000 * 60 * 60, // 1 hour - sectors rarely change
  });
}

/**
 * Hook for registering a new member via web form
 */
export function useRegisterMember() {
  return useMutation({
    mutationFn: (data: RegisterRequest) => authApi.registerMember(data),
  });
}
