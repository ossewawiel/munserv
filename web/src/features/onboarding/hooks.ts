import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { onboardingApi } from './api';
import type { ChangePasswordRequest, CompleteProfileRequest } from './types';

/**
 * Query keys for onboarding
 */
export const onboardingKeys = {
  all: ['onboarding'] as const,
  status: () => [...onboardingKeys.all, 'status'] as const,
};

/**
 * Hook to get current onboarding status
 */
export function useOnboardingStatus() {
  return useQuery({
    queryKey: onboardingKeys.status(),
    queryFn: onboardingApi.getStatus,
  });
}

/**
 * Hook to change password during onboarding
 */
export function useChangePassword() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: ChangePasswordRequest) => onboardingApi.changePassword(data),
    onSuccess: (response) => {
      // Update cached status
      queryClient.setQueryData(onboardingKeys.status(), response);
      // Also update the admin in localStorage to reflect new onboarding status
      const adminStr = localStorage.getItem('admin');
      if (adminStr) {
        try {
          const admin = JSON.parse(adminStr);
          admin.onboardingStatus = response.status;
          localStorage.setItem('admin', JSON.stringify(admin));
        } catch {
          // Ignore parse errors
        }
      }
    },
  });
}

/**
 * Hook to complete profile during onboarding
 */
export function useCompleteProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CompleteProfileRequest) => onboardingApi.completeProfile(data),
    onSuccess: (response) => {
      // Update cached status
      queryClient.setQueryData(onboardingKeys.status(), response);
      // Also update the admin in localStorage to reflect new onboarding status
      const adminStr = localStorage.getItem('admin');
      if (adminStr) {
        try {
          const admin = JSON.parse(adminStr);
          admin.onboardingStatus = response.status;
          admin.displayName = response.displayName;
          localStorage.setItem('admin', JSON.stringify(admin));
        } catch {
          // Ignore parse errors
        }
      }
    },
  });
}
