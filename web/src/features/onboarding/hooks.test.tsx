import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import type { ReactNode } from 'react';

import { server } from '@/test/mocks/server';
import { useOnboardingStatus, useChangePassword, useCompleteProfile } from './hooks';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
      mutations: {
        retry: false,
      },
    },
  });
}

function createWrapper(queryClient: QueryClient) {
  return function Wrapper({ children }: { children: ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    );
  };
}

describe('onboarding hooks', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  describe('useOnboardingStatus', () => {
    it('should fetch onboarding status', async () => {
      server.use(
        http.get('*/admin/onboarding/status', () => {
          return HttpResponse.json({
            status: 'pending',
            requiresPasswordChange: true,
            requiresProfileCompletion: false,
            isOnboarded: false,
            displayName: 'Test User',
          });
        })
      );

      const queryClient = createTestQueryClient();
      const wrapper = createWrapper(queryClient);

      const { result } = renderHook(() => useOnboardingStatus(), { wrapper });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toEqual({
        status: 'pending',
        requiresPasswordChange: true,
        requiresProfileCompletion: false,
        isOnboarded: false,
        displayName: 'Test User',
      });
    });
  });

  describe('useChangePassword', () => {
    it('should change password successfully', async () => {
      server.use(
        http.post('*/admin/onboarding/change-password', () => {
          return HttpResponse.json({
            status: 'password_changed',
            requiresPasswordChange: false,
            requiresProfileCompletion: true,
            isOnboarded: false,
            displayName: 'Test User',
          });
        })
      );

      // Set up initial admin in localStorage
      localStorage.setItem(
        'admin',
        JSON.stringify({
          id: '123',
          onboardingStatus: 'pending',
        })
      );

      const queryClient = createTestQueryClient();
      const wrapper = createWrapper(queryClient);

      const { result } = renderHook(() => useChangePassword(), { wrapper });

      result.current.mutate({ newPassword: 'NewPassword123' });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toEqual({
        status: 'password_changed',
        requiresPasswordChange: false,
        requiresProfileCompletion: true,
        isOnboarded: false,
        displayName: 'Test User',
      });

      // Verify localStorage was updated
      const storedAdmin = JSON.parse(localStorage.getItem('admin') ?? '{}');
      expect(storedAdmin.onboardingStatus).toBe('password_changed');
    });

    it('should handle change password error', async () => {
      server.use(
        http.post('*/admin/onboarding/change-password', () => {
          return HttpResponse.json(
            { code: 'validation_error', message: 'Password too weak' },
            { status: 400 }
          );
        })
      );

      const queryClient = createTestQueryClient();
      const wrapper = createWrapper(queryClient);

      const { result } = renderHook(() => useChangePassword(), { wrapper });

      result.current.mutate({ newPassword: 'weak' });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useCompleteProfile', () => {
    it('should complete profile successfully', async () => {
      server.use(
        http.post('*/admin/onboarding/complete-profile', () => {
          return HttpResponse.json({
            status: 'active',
            requiresPasswordChange: false,
            requiresProfileCompletion: false,
            isOnboarded: true,
            displayName: 'Updated Name',
          });
        })
      );

      // Set up initial admin in localStorage
      localStorage.setItem(
        'admin',
        JSON.stringify({
          id: '123',
          displayName: 'Test User',
          onboardingStatus: 'password_changed',
        })
      );

      const queryClient = createTestQueryClient();
      const wrapper = createWrapper(queryClient);

      const { result } = renderHook(() => useCompleteProfile(), { wrapper });

      result.current.mutate({ displayName: 'Updated Name' });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toEqual({
        status: 'active',
        requiresPasswordChange: false,
        requiresProfileCompletion: false,
        isOnboarded: true,
        displayName: 'Updated Name',
      });

      // Verify localStorage was updated
      const storedAdmin = JSON.parse(localStorage.getItem('admin') ?? '{}');
      expect(storedAdmin.onboardingStatus).toBe('active');
      expect(storedAdmin.displayName).toBe('Updated Name');
    });

    it('should complete profile without display name', async () => {
      server.use(
        http.post('*/admin/onboarding/complete-profile', () => {
          return HttpResponse.json({
            status: 'active',
            requiresPasswordChange: false,
            requiresProfileCompletion: false,
            isOnboarded: true,
            displayName: 'Test User',
          });
        })
      );

      localStorage.setItem(
        'admin',
        JSON.stringify({
          id: '123',
          displayName: 'Test User',
          onboardingStatus: 'password_changed',
        })
      );

      const queryClient = createTestQueryClient();
      const wrapper = createWrapper(queryClient);

      const { result } = renderHook(() => useCompleteProfile(), { wrapper });

      result.current.mutate({});

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });
    });
  });
});
