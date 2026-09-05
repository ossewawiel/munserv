import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { AxiosError } from 'axios';
import { server } from '@/test/mocks/server';
import { useSupportGrants, useGrantSupportAccess, useRevokeSupportGrant } from './hooks';
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

  describe('useRevokeSupportGrant', () => {
    it('should invalidate the grants list after a revoke', async () => {
      const queryClient = createTestQueryClient();
      const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries');
      const wrapper = ({ children }: { children: ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      );

      server.use(
        http.delete('*/support-access/grants/:id', () => new HttpResponse(null, { status: 204 }))
      );

      const { result } = renderHook(() => useRevokeSupportGrant(), { wrapper });

      result.current.mutate('grant-1');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['support-grants'] });
    });

    it('should surface grant_not_active when the revoke conflicts', async () => {
      server.use(
        http.delete('*/support-access/grants/:id', () =>
          HttpResponse.json(
            { code: 'grant_not_active', message: 'The grant is no longer active' },
            { status: 409 }
          )
        )
      );

      const { result } = renderHook(() => useRevokeSupportGrant(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('grant-1');

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });

      const error = result.current.error;
      expect(error).toBeInstanceOf(AxiosError);
      if (error instanceof AxiosError) {
        expect(error.response?.data.code).toBe('grant_not_active');
      }
    });
  });
});
