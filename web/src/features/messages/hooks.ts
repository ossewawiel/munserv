import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { messagesApi } from './api';
import type {
  MessageActionRequest,
  MessageFilterParams,
} from '@/shared/types/message';

/**
 * Query messages list with optional filters
 */
export function useMessages(params?: MessageFilterParams) {
  return useQuery({
    queryKey: ['messages', params],
    queryFn: () => messagesApi.getAll(params),
  });
}

/**
 * Query a single message by ID
 */
export function useMessage(id: string) {
  return useQuery({
    queryKey: ['messages', id],
    queryFn: () => messagesApi.getById(id),
    enabled: !!id,
  });
}

/**
 * Query unread message count (for badge display)
 */
export function useUnreadCount() {
  return useQuery({
    queryKey: ['messages', 'unreadCount'],
    queryFn: async () => {
      const response = await messagesApi.getAll({ status: 'unread', size: 1 });
      return response.unreadCount;
    },
    refetchInterval: 60000, // Refresh every minute
  });
}

/**
 * Mutation to mark a message as read
 */
export function useMarkAsRead() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => messagesApi.markAsRead(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}

/**
 * Mutation to perform an action on a message (accept, decline, approve, etc.)
 */
export function useMessageAction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, action }: { id: string; action: MessageActionRequest }) =>
      messagesApi.performAction(id, action),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}
