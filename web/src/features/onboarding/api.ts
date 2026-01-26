import { apiClient } from '@/lib/api-client';
import type {
  OnboardingStatusResponse,
  ChangePasswordRequest,
  CompleteProfileRequest,
} from './types';

export const onboardingApi = {
  /**
   * Get current onboarding status for the authenticated admin
   */
  getStatus: () =>
    apiClient
      .get<OnboardingStatusResponse>('/admin/onboarding/status')
      .then((r) => r.data),

  /**
   * Change password during onboarding
   */
  changePassword: (data: ChangePasswordRequest) =>
    apiClient
      .post<OnboardingStatusResponse>('/admin/onboarding/change-password', data)
      .then((r) => r.data),

  /**
   * Complete profile during onboarding
   */
  completeProfile: (data: CompleteProfileRequest) =>
    apiClient
      .post<OnboardingStatusResponse>('/admin/onboarding/complete-profile', data)
      .then((r) => r.data),
};
