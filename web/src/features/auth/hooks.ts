import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { authApi } from './api';
import type { LoginRequest } from './types';

const ACCESS_TOKEN_KEY = 'accessToken';
const REFRESH_TOKEN_KEY = 'refreshToken';
const ADMIN_KEY = 'admin';

export function useLogin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: LoginRequest) => authApi.login(data),
    onSuccess: (response) => {
      // Store tokens and admin in localStorage
      localStorage.setItem(ACCESS_TOKEN_KEY, response.tokens.accessToken);
      localStorage.setItem(REFRESH_TOKEN_KEY, response.tokens.refreshToken);
      localStorage.setItem(ADMIN_KEY, JSON.stringify(response.profile.admin));
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
      // Clear React Query cache
      queryClient.clear();
    },
  });
}

export function useSectors() {
  return useQuery({
    queryKey: ['sectors'],
    queryFn: () => authApi.getSectors(),
  });
}
