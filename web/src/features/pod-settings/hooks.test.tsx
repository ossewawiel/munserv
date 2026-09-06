import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import { server } from '@/test/mocks/server';
import { usePodSettings, useUpdatePodSettings, podSettingsKeys } from './hooks';
import { mockPodSettings } from '@/test/mocks/handlers';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

function createWrapper(queryClient: QueryClient) {
  return function Wrapper({ children }: { children: ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

describe('pod-settings hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('usePodSettings', () => {
    it('should load the pod settings', async () => {
      const queryClient = createTestQueryClient();
      const { result } = renderHook(() => usePodSettings(), {
        wrapper: createWrapper(queryClient),
      });

      await waitFor(() => expect(result.current.isSuccess).toBe(true));

      expect(result.current.data?.name).toBe(mockPodSettings.name);
    });

    it('should not fetch when disabled', async () => {
      const queryClient = createTestQueryClient();
      const { result } = renderHook(() => usePodSettings({ enabled: false }), {
        wrapper: createWrapper(queryClient),
      });

      expect(result.current.isFetching).toBe(false);
      expect(result.current.data).toBeUndefined();
      expect(result.current.fetchStatus).toBe('idle');
    });
  });

  describe('useUpdatePodSettings', () => {
    it('should replace the cached settings after an update', async () => {
      const queryClient = createTestQueryClient();
      queryClient.setQueryData(podSettingsKeys.all, mockPodSettings);

      const { result } = renderHook(() => useUpdatePodSettings(), {
        wrapper: createWrapper(queryClient),
      });

      result.current.mutate({ name: 'Ward 42' });

      await waitFor(() =>
        expect(queryClient.getQueryData(podSettingsKeys.all)).toEqual({
          name: 'Ward 42',
          displayName: 'Munserv Pod Ward 42',
          logoUrl: mockPodSettings.logoUrl,
        })
      );
    });
  });
});
