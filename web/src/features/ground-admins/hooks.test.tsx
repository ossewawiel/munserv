import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import {
  useGroundAdmins,
  useInviteGroundAdmin,
  useApproveGroundAdmin,
  useDeclineGroundAdmin,
  useRevokeGroundAdmin,
  useUpdateGroundAdminStatus,
} from './hooks';
import { mockGroundAdmins } from '@/test/mocks/handlers';
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

describe('ground-admins hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useGroundAdmins', () => {
    it('should fetch ground admins successfully', async () => {
      const { result } = renderHook(() => useGroundAdmins(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items).toHaveLength(mockGroundAdmins.length);
    });

    it('should filter ground admins by status', async () => {
      const { result } = renderHook(() => useGroundAdmins('active'), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items.every((ga) => ga.status === 'active')).toBe(
        true
      );
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useGroundAdmins(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/sectors/:sectorId/ground-admins', () => {
          return HttpResponse.json({ message: 'Server error' }, { status: 500 });
        })
      );

      const { result } = renderHook(() => useGroundAdmins(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useInviteGroundAdmin', () => {
    it('should invite a member successfully', async () => {
      const { result } = renderHook(() => useInviteGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({ memberId: 'member-2', message: 'Please join us!' });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('pending');
    });

    it('should handle already ground admin error', async () => {
      const { result } = renderHook(() => useInviteGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({ memberId: 'member-1' });

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

      const { result } = renderHook(() => useInviteGroundAdmin(), { wrapper });

      result.current.mutate({ memberId: 'member-2' });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['groundAdmins'] });
      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['members'] });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useInviteGroundAdmin(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });
  });

  describe('useApproveGroundAdmin', () => {
    it('should approve application successfully', async () => {
      const { result } = renderHook(() => useApproveGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({ memberId: 'member-2', applicationId: 'app-123' });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('approved');
      expect(result.current.data?.member?.isGroundAdmin).toBe(true);
    });

    it('should handle error', async () => {
      server.use(
        http.post('*/members/:memberId/ground-admin/approve', () => {
          return HttpResponse.json({ message: 'Not found' }, { status: 404 });
        })
      );

      const { result } = renderHook(() => useApproveGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({ memberId: 'unknown', applicationId: 'app-123' });

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

      const { result } = renderHook(() => useApproveGroundAdmin(), { wrapper });

      result.current.mutate({ memberId: 'member-2', applicationId: 'app-123' });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['groundAdmins'] });
      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['members'] });
      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['messages'] });
    });
  });

  describe('useDeclineGroundAdmin', () => {
    it('should decline application successfully', async () => {
      const { result } = renderHook(() => useDeclineGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        memberId: 'member-2',
        applicationId: 'app-123',
        reason: 'Insufficient experience',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('declined');
    });

    it('should handle error', async () => {
      server.use(
        http.post('*/members/:memberId/ground-admin/decline', () => {
          return HttpResponse.json({ message: 'Not found' }, { status: 404 });
        })
      );

      const { result } = renderHook(() => useDeclineGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        memberId: 'unknown',
        applicationId: 'app-123',
        reason: 'Some reason',
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

      const { result } = renderHook(() => useDeclineGroundAdmin(), { wrapper });

      result.current.mutate({
        memberId: 'member-2',
        applicationId: 'app-123',
        reason: 'Some reason',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['groundAdmins'] });
      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['members'] });
      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['messages'] });
    });
  });

  describe('useRevokeGroundAdmin', () => {
    it('should revoke ground admin status successfully', async () => {
      const { result } = renderHook(() => useRevokeGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        memberId: 'member-1',
        reason: 'Inactive for too long',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('revoked');
    });

    it('should handle error when member is not a ground admin', async () => {
      const { result } = renderHook(() => useRevokeGroundAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        memberId: 'member-2',
        reason: 'Some reason',
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

      const { result } = renderHook(() => useRevokeGroundAdmin(), { wrapper });

      result.current.mutate({
        memberId: 'member-1',
        reason: 'Some reason',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['groundAdmins'] });
      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['members'] });
    });
  });

  describe('useUpdateGroundAdminStatus', () => {
    it('should update status to on_hold successfully', async () => {
      const { result } = renderHook(() => useUpdateGroundAdminStatus(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        memberId: 'member-1',
        status: 'on_hold',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('on_hold');
    });

    it('should update status to active successfully', async () => {
      const { result } = renderHook(() => useUpdateGroundAdminStatus(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        memberId: 'member-5', // on_hold member
        status: 'active',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('active');
    });

    it('should handle error when member is not a ground admin', async () => {
      const { result } = renderHook(() => useUpdateGroundAdminStatus(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        memberId: 'member-2',
        status: 'on_hold',
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

      const { result } = renderHook(() => useUpdateGroundAdminStatus(), { wrapper });

      result.current.mutate({
        memberId: 'member-1',
        status: 'on_hold',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['groundAdmins'] });
      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['members'] });
    });
  });
});
