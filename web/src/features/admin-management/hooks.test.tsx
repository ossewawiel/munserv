import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import {
  useAdmins,
  useAdmin,
  useCreateAdmin,
  useUpdateAdmin,
  useDeleteAdmin,
} from './hooks';
import { mockAdmins } from '@/test/mocks/handlers';
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

describe('admin-management hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useAdmins', () => {
    it('should fetch admins successfully', async () => {
      const { result } = renderHook(() => useAdmins(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items).toHaveLength(mockAdmins.length);
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useAdmins(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/admins', () => {
          return HttpResponse.json({ message: 'Server error' }, { status: 500 });
        })
      );

      const { result } = renderHook(() => useAdmins(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useAdmin', () => {
    it('should fetch single admin successfully', async () => {
      const { result } = renderHook(() => useAdmin('admin-2'), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.id).toBe('admin-2');
      expect(result.current.data?.displayName).toBe('Sector Admin One');
    });

    it('should not fetch when id is empty', () => {
      const { result } = renderHook(() => useAdmin(''), {
        wrapper: createWrapper(),
      });

      expect(result.current.fetchStatus).toBe('idle');
    });

    it('should handle not found error', async () => {
      const { result } = renderHook(() => useAdmin('unknown'), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useCreateAdmin', () => {
    it('should create admin successfully', async () => {
      const { result } = renderHook(() => useCreateAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        email: 'newadmin@example.com',
        displayName: 'New Admin',
        role: 'sector_admin',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.temporaryPassword).toBeDefined();
      expect(result.current.data?.email).toBe('newadmin@example.com');
    });

    it('should handle email already exists error', async () => {
      const { result } = renderHook(() => useCreateAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        email: 'sectoradmin1@ward42.example.com', // existing email
        displayName: 'Duplicate Admin',
        role: 'sector_admin',
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

      const { result } = renderHook(() => useCreateAdmin(), { wrapper });

      result.current.mutate({
        email: 'newadmin@example.com',
        displayName: 'New Admin',
        role: 'sector_admin',
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['admins'] });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useCreateAdmin(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });
  });

  describe('useUpdateAdmin', () => {
    it('should update admin successfully', async () => {
      const { result } = renderHook(() => useUpdateAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        id: 'admin-2',
        request: { displayName: 'Updated Name' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.displayName).toBe('Updated Name');
    });

    it('should handle not found error', async () => {
      const { result } = renderHook(() => useUpdateAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        id: 'unknown',
        request: { displayName: 'Updated Name' },
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

      const { result } = renderHook(() => useUpdateAdmin(), { wrapper });

      result.current.mutate({
        id: 'admin-2',
        request: { displayName: 'Updated Name' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['admins'] });
    });
  });

  describe('useDeleteAdmin', () => {
    it('should delete admin successfully', async () => {
      const { result } = renderHook(() => useDeleteAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('admin-2');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });
    });

    it('should handle not found error', async () => {
      const { result } = renderHook(() => useDeleteAdmin(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('unknown');

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

      const { result } = renderHook(() => useDeleteAdmin(), { wrapper });

      result.current.mutate('admin-2');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['admins'] });
    });
  });
});
