import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { AxiosError } from 'axios';
import type { ReactNode } from 'react';
import { server } from '@/test/mocks/server';
import { useCreatePodAdministrator } from './hooks';

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
      mutations: { retry: false },
    },
  });
  return function Wrapper({ children }: { children: ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

describe('pod-chief hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useCreatePodAdministrator', () => {
    it('should surface a 409 conflict to the caller', async () => {
      server.use(
        http.post('*/pod/administrators', () =>
          HttpResponse.json(
            { error: { code: 'email_exists', message: 'Email admin@example.com is already registered' } },
            { status: 409 }
          )
        )
      );

      const { result } = renderHook(() => useCreatePodAdministrator(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        email: 'admin@example.com',
        displayName: 'New Admin',
        role: 'pod_admin',
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });

      const error = result.current.error;
      expect(error).toBeInstanceOf(AxiosError);
      if (error instanceof AxiosError) {
        expect(error.response?.status).toBe(409);
        expect(error.response?.data.error.code).toBe('email_exists');
      }
    });
  });
});
