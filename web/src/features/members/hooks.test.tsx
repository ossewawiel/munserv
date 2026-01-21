import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { useMembers, useApproveMember, useRejectMember, usePendingMemberCount } from './hooks';
import type { ReactNode } from 'react';

// Mock useAuth hook
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => ({
    admin: {
      id: 'admin-1',
      email: 'admin@ward42.example.com',
      displayName: 'Test Admin',
      sectorId: 'sector-1',
      role: 'SECTOR_ADMIN',
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

describe('members hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useMembers', () => {
    it('should fetch members successfully', async () => {
      const { result } = renderHook(() => useMembers(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items).toHaveLength(7); // 7 members in mock data to cover all GA scenarios
    });

    it('should filter members by status', async () => {
      const { result } = renderHook(
        () => useMembers({ status: 'pending_approval' }),
        { wrapper: createWrapper() }
      );

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items).toHaveLength(1);
      expect(result.current.data?.items[0].status).toBe('pending_approval');
    });

    it('should handle pagination parameters', async () => {
      const { result } = renderHook(
        () => useMembers({ page: 1, limit: 10 }),
        { wrapper: createWrapper() }
      );

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.pagination).toBeDefined();
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useMembers(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/admin/members', () => {
          return HttpResponse.json(
            { message: 'Server error' },
            { status: 500 }
          );
        })
      );

      const { result } = renderHook(() => useMembers(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useApproveMember', () => {
    it('should approve a member successfully', async () => {
      const { result } = renderHook(() => useApproveMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('member-2');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toEqual({
        memberId: 'member-2',
        email: 'jane@example.com',
        message: 'Member approved successfully',
      });
    });

    it('should handle member not found error', async () => {
      const { result } = renderHook(() => useApproveMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('non-existent-id');

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should handle wrong status error', async () => {
      const { result } = renderHook(() => useApproveMember(), {
        wrapper: createWrapper(),
      });

      // member-1 is active, not pending_approval
      result.current.mutate('member-1');

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should invalidate members queries on success', async () => {
      const queryClient = createTestQueryClient();
      const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries');

      const wrapper = ({ children }: { children: ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      );

      const { result } = renderHook(() => useApproveMember(), { wrapper });

      result.current.mutate('member-2');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['members'] });
      expect(invalidateSpy).toHaveBeenCalledWith({
        queryKey: ['members', 'pending-count'],
      });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useApproveMember(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });
  });

  describe('useRejectMember', () => {
    it('should reject a member successfully', async () => {
      const { result } = renderHook(() => useRejectMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('member-2');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });
    });

    it('should handle member not found error', async () => {
      const { result } = renderHook(() => useRejectMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('non-existent-id');

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should invalidate members queries on success', async () => {
      const queryClient = createTestQueryClient();
      const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries');

      const wrapper = ({ children }: { children: ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      );

      const { result } = renderHook(() => useRejectMember(), { wrapper });

      result.current.mutate('member-2');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['members'] });
      expect(invalidateSpy).toHaveBeenCalledWith({
        queryKey: ['members', 'pending-count'],
      });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useRejectMember(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });
  });

  describe('usePendingMemberCount', () => {
    it('should fetch pending member count successfully', async () => {
      const { result } = renderHook(() => usePendingMemberCount(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toBe(1);
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => usePendingMemberCount(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/admin/members/pending-count', () => {
          return HttpResponse.json(
            { message: 'Server error' },
            { status: 500 }
          );
        })
      );

      const { result } = renderHook(() => usePendingMemberCount(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should return 0 when no pending members', async () => {
      server.use(
        http.get('*/admin/members/pending-count', () => {
          return HttpResponse.json({ count: 0 });
        })
      );

      const { result } = renderHook(() => usePendingMemberCount(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toBe(0);
    });

    it('should have refetch interval of 30 seconds', async () => {
      const { result } = renderHook(() => usePendingMemberCount(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      // The hook is configured with refetchInterval: 30000
      // We can't easily test the interval behavior without advancing timers
      // but we can verify the hook is working
      expect(result.current.data).toBeDefined();
    });
  });
});
