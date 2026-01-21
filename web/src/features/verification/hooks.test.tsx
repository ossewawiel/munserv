import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { useVerificationHistory, useRequestVerification } from './hooks';
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
    return (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    );
  };
}

describe('verification hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useVerificationHistory', () => {
    it('should fetch verification history successfully', async () => {
      const { result } = renderHook(() => useVerificationHistory('issue-1'), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items).toBeDefined();
    });

    it('should not fetch when issueId is empty', () => {
      const { result } = renderHook(() => useVerificationHistory(''), {
        wrapper: createWrapper(),
      });

      expect(result.current.isFetching).toBe(false);
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useVerificationHistory('issue-1'), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/issues/:issueId/verifications', () => {
          return HttpResponse.json({ message: 'Server error' }, { status: 500 });
        })
      );

      const { result } = renderHook(() => useVerificationHistory('issue-1'), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useRequestVerification', () => {
    it('should request verification successfully', async () => {
      const { result } = renderHook(() => useRequestVerification(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        issueId: 'issue-1',
        request: { type: 'existence' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.verificationType).toBe('existence');
      expect(result.current.data?.status).toBe('pending');
    });

    it('should request fix verification successfully', async () => {
      const { result } = renderHook(() => useRequestVerification(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        issueId: 'issue-1',
        request: { type: 'fix' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.verificationType).toBe('fix');
    });

    it('should assign to specific ground admin', async () => {
      const { result } = renderHook(() => useRequestVerification(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        issueId: 'issue-1',
        request: { type: 'existence', assignTo: 'member-1' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.assignedTo).toBe('member-1');
    });

    it('should handle error', async () => {
      server.use(
        http.post('*/issues/:issueId/request-verification', () => {
          return HttpResponse.json(
            { message: 'Invalid state' },
            { status: 400 }
          );
        })
      );

      const { result } = renderHook(() => useRequestVerification(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        issueId: 'issue-1',
        request: { type: 'existence' },
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

      const { result } = renderHook(() => useRequestVerification(), { wrapper });

      result.current.mutate({
        issueId: 'issue-1',
        request: { type: 'existence' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({
        queryKey: ['verifications', 'issue-1'],
      });
      expect(invalidateSpy).toHaveBeenCalledWith({
        queryKey: ['issues', 'issue-1'],
      });
      expect(invalidateSpy).toHaveBeenCalledWith({
        queryKey: ['messages'],
      });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useRequestVerification(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });
  });
});
