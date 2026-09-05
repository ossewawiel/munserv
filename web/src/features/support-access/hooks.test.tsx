import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { AxiosError } from 'axios';
import { server } from '@/test/mocks/server';
import { useSupportGrants, useGrantSupportAccess } from './hooks';
import { mockSupportGrants } from '@/test/mocks/handlers';
import type { ReactNode } from 'react';

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
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

describe('support-access hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useSupportGrants', () => {
    it('should return grants when the list endpoint resolves', async () => {
      const { result } = renderHook(() => useSupportGrants(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items).toHaveLength(mockSupportGrants.length);
    });
  });

  describe('useGrantSupportAccess', () => {
    it('should expose the conflict body when granting returns 409', async () => {
      server.use(
        http.post('*/support-access/grants', () =>
          HttpResponse.json(
            { code: 'active_grant_exists', message: 'An active grant already exists' },
            { status: 409 }
          )
        )
      );

      const { result } = renderHook(() => useGrantSupportAccess(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({ grantedRole: 'pod_admin', purpose: 'Investigate duplicate reports' });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });

      const error = result.current.error;
      expect(error).toBeInstanceOf(AxiosError);
      if (error instanceof AxiosError) {
        expect(error.response?.data.code).toBe('active_grant_exists');
      }
    });
  });
});
