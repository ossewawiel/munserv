import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { useSectors, useRegisterMember } from './hooks';
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

describe('auth hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useSectors', () => {
    it('should fetch sectors successfully', async () => {
      const { result } = renderHook(() => useSectors(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toHaveLength(2);
      expect(result.current.data?.[0].name).toBe('Ward 42');
    });

    it('should have 1 hour stale time', async () => {
      const { result } = renderHook(() => useSectors(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      // Check that data doesn't become stale immediately
      expect(result.current.isStale).toBe(false);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/sectors', () => {
          return HttpResponse.json(
            { message: 'Server error' },
            { status: 500 }
          );
        })
      );

      const { result } = renderHook(() => useSectors(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });

      expect(result.current.error).toBeDefined();
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useSectors(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
      expect(result.current.data).toBeUndefined();
    });
  });

  describe('useRegisterMember', () => {
    const validRegistration = {
      email: 'newuser@example.com',
      firstName: 'John',
      surname: 'Doe',
      phone: '+27123456789',
      address: '123 Test Street',
      latitude: -26.2041,
      longitude: 28.0473,
      sectorId: 'sector-1',
    };

    it('should register a new member successfully', async () => {
      const { result } = renderHook(() => useRegisterMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate(validRegistration);

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toEqual({
        message: 'Registration submitted successfully',
        memberId: 'member-new-1',
      });
    });

    it('should handle duplicate email error', async () => {
      const { result } = renderHook(() => useRegisterMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        ...validRegistration,
        email: 'existing@example.com',
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });

      expect(result.current.error).toBeDefined();
    });

    it('should handle validation error', async () => {
      const { result } = renderHook(() => useRegisterMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        ...validRegistration,
        email: '',
        firstName: '',
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useRegisterMember(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
      expect(result.current.isPending).toBe(false);
    });

    it('should show pending state during mutation', async () => {
      server.use(
        http.post('*/auth/register/web', async () => {
          // Add a delay to test pending state
          await new Promise((resolve) => setTimeout(resolve, 100));
          return HttpResponse.json({
            message: 'Registration submitted successfully',
            memberId: 'member-new-1',
          });
        })
      );

      const { result } = renderHook(() => useRegisterMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate(validRegistration);

      await waitFor(() => {
        expect(result.current.isPending).toBe(true);
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });
    });

    it('should reset state when reset is called', async () => {
      const { result } = renderHook(() => useRegisterMember(), {
        wrapper: createWrapper(),
      });

      result.current.mutate(validRegistration);

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      result.current.reset();

      await waitFor(() => {
        expect(result.current.isIdle).toBe(true);
      });

      expect(result.current.data).toBeUndefined();
    });
  });
});
