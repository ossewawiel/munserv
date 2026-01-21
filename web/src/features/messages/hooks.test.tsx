import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import {
  useMessages,
  useMessage,
  useUnreadCount,
  useMarkAsRead,
  useMessageAction,
} from './hooks';
import { mockMessages } from '@/test/mocks/handlers';
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

describe('messages hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  describe('useMessages', () => {
    it('should fetch messages successfully', async () => {
      const { result } = renderHook(() => useMessages(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.items).toHaveLength(mockMessages.length);
      expect(result.current.data?.unreadCount).toBe(2);
    });

    it('should filter messages by status', async () => {
      const { result } = renderHook(
        () => useMessages({ status: 'unread' }),
        { wrapper: createWrapper() }
      );

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      // All returned messages should be unread
      expect(result.current.data?.items.every((m) => m.status === 'unread')).toBe(
        true
      );
    });

    it('should support pagination parameters', async () => {
      const { result } = renderHook(() => useMessages({ page: 2, size: 10 }), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.page).toBe(2);
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useMessages(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should handle fetch error', async () => {
      server.use(
        http.get('*/messages', () => {
          return HttpResponse.json({ message: 'Server error' }, { status: 500 });
        })
      );

      const { result } = renderHook(() => useMessages(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useMessage', () => {
    it('should fetch a single message', async () => {
      const { result } = renderHook(() => useMessage('msg-1'), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.id).toBe('msg-1');
      expect(result.current.data?.type).toBe('ground_admin_application');
    });

    it('should not fetch when id is empty', () => {
      const { result } = renderHook(() => useMessage(''), {
        wrapper: createWrapper(),
      });

      // Query should be disabled when id is falsy
      expect(result.current.isFetching).toBe(false);
    });

    it('should handle message not found error', async () => {
      server.use(
        http.get('*/messages/:id', () => {
          return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
        })
      );

      const { result } = renderHook(() => useMessage('non-existent'), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });
  });

  describe('useUnreadCount', () => {
    it('should fetch unread message count', async () => {
      const { result } = renderHook(() => useUnreadCount(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toBe(2); // msg-1 and msg-2 are unread
    });

    it('should return loading state initially', () => {
      const { result } = renderHook(() => useUnreadCount(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isLoading).toBe(true);
    });

    it('should return 0 when no unread messages', async () => {
      server.use(
        http.get('*/messages', () => {
          return HttpResponse.json({
            items: [],
            total: 0,
            page: 1,
            unreadCount: 0,
          });
        })
      );

      const { result } = renderHook(() => useUnreadCount(), {
        wrapper: createWrapper(),
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data).toBe(0);
    });
  });

  describe('useMarkAsRead', () => {
    it('should mark message as read successfully', async () => {
      const { result } = renderHook(() => useMarkAsRead(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('msg-1');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('read');
      expect(result.current.data?.readAt).toBeDefined();
    });

    it('should handle error for non-existent message', async () => {
      server.use(
        http.patch('*/messages/:id/read', () => {
          return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
        })
      );

      const { result } = renderHook(() => useMarkAsRead(), {
        wrapper: createWrapper(),
      });

      result.current.mutate('non-existent');

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should invalidate messages queries on success', async () => {
      const queryClient = createTestQueryClient();
      const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries');

      const wrapper = ({ children }: { children: ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      );

      const { result } = renderHook(() => useMarkAsRead(), { wrapper });

      result.current.mutate('msg-1');

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['messages'] });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useMarkAsRead(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });
  });

  describe('useMessageAction', () => {
    it('should perform approve action successfully', async () => {
      const { result } = renderHook(() => useMessageAction(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        id: 'msg-1',
        action: { action: 'approve', note: 'Good candidate' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.status).toBe('actioned');
      expect(result.current.data?.actionResult).toBe('approve');
    });

    it('should perform decline action with note', async () => {
      const { result } = renderHook(() => useMessageAction(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        id: 'msg-1',
        action: { action: 'decline', note: 'Insufficient experience' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(result.current.data?.actionResult).toBe('decline');
    });

    it('should handle already actioned error', async () => {
      server.use(
        http.post('*/messages/:id/action', () => {
          return HttpResponse.json(
            { message: 'Message already actioned' },
            { status: 409 }
          );
        })
      );

      const { result } = renderHook(() => useMessageAction(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        id: 'msg-4',
        action: { action: 'acknowledge' },
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should handle message not found error', async () => {
      server.use(
        http.post('*/messages/:id/action', () => {
          return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
        })
      );

      const { result } = renderHook(() => useMessageAction(), {
        wrapper: createWrapper(),
      });

      result.current.mutate({
        id: 'non-existent',
        action: { action: 'approve' },
      });

      await waitFor(() => {
        expect(result.current.isError).toBe(true);
      });
    });

    it('should invalidate messages queries on success', async () => {
      const queryClient = createTestQueryClient();
      const invalidateSpy = vi.spyOn(queryClient, 'invalidateQueries');

      const wrapper = ({ children }: { children: ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      );

      const { result } = renderHook(() => useMessageAction(), { wrapper });

      result.current.mutate({
        id: 'msg-1',
        action: { action: 'approve' },
      });

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true);
      });

      expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['messages'] });
    });

    it('should be idle initially', () => {
      const { result } = renderHook(() => useMessageAction(), {
        wrapper: createWrapper(),
      });

      expect(result.current.isIdle).toBe(true);
    });
  });
});
