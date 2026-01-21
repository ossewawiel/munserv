import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { useSectorSettings, useUpdateSectorSettings } from './hooks';
import { mockSectorSettings } from '@/test/mocks/handlers';
import type { ReactNode } from 'react';

// Mock useAuth hook
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => ({
    admin: {
      id: 'admin-1',
      email: 'admin@ward42.example.com',
      displayName: 'Test Admin',
      sectorId: 'sector-1',
      role: 'SECTOR_CHIEF',
    },
    isAuthenticated: true,
  }),
}));

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

function createWrapper() {
  const queryClient = createTestQueryClient();
  return function Wrapper({ children }: { children: ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    );
  };
}

describe('sector-settings hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useSectorSettings', () => {
    it('should fetch sector settings successfully', async () => {
      const { result } = renderHook(() => useSectorSettings(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.newIssueVerificationMode).toBe(
        mockSectorSettings.newIssueVerificationMode
      );
      expect(result.current.data?.fixVerificationMode).toBe(
        mockSectorSettings.fixVerificationMode
      );
      expect(result.current.data?.daysFixedBeforeClosed).toBe(
        mockSectorSettings.daysFixedBeforeClosed
      );
      expect(result.current.data?.minimumGroundAdmins).toBe(
        mockSectorSettings.minimumGroundAdmins
      );
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useSectorSettings(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/sectors/:sectorId/settings', () => {
          return HttpResponse.json({ message: 'Forbidden' }, { status: 403 });
        })
      );

      const { result } = renderHook(() => useSectorSettings(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useUpdateSectorSettings', () => {
    it('should update settings successfully', async () => {
      const { result } = renderHook(() => useUpdateSectorSettings(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        newIssueVerificationMode: 'admin_assigns',
        daysFixedBeforeClosed: 14,
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.newIssueVerificationMode).toBe('admin_assigns');
      expect(result.current.data?.daysFixedBeforeClosed).toBe(14);
    });

    it('should update single setting', async () => {
      const { result } = renderHook(() => useUpdateSectorSettings(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        minimumGroundAdmins: 5,
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.minimumGroundAdmins).toBe(5);
    });

    it('should handle validation error', async () => {
      const { result } = renderHook(() => useUpdateSectorSettings(), {
        wrapper: createWrapper(),
      });

      // This should fail due to validation in the mock handler
      result.current.mutate({
        daysFixedBeforeClosed: 0, // Below minimum of 1
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should invalidate queries on success', async () => {
      const queryClient = createTestQueryClient();
      const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries');

      const wrapper = ({ children }: { children: ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      );

      const { result } = renderHook(() => useUpdateSectorSettings(), { wrapper });

      result.current.mutate({
        daysFixedBeforeClosed: 10,
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({
        queryKey: ['sectorSettings', 'sector-1'],
      });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useUpdateSectorSettings(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });

    it('should handle forbidden error', async () => {
      server.use(
        http.patch('*/sectors/:sectorId/settings', () => {
          return HttpResponse.json({ message: 'Forbidden' }, { status: 403 });
        })
      );

      const { result } = renderHook(() => useUpdateSectorSettings(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        daysFixedBeforeClosed: 7,
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });
});
