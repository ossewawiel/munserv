import { apiClient } from '@/lib/api-client';
import type {
  Message,
  MessageListResponse,
  MessageActionRequest,
  MessageFilterParams,
} from '@/shared/types/message';

export const messagesApi = {
  /**
   * Get list of messages for the current user
   */
  getAll: (params?: MessageFilterParams) =>
    apiClient
      .get<MessageListResponse>('/messages', { params })
      .then((r) => r.data),

  /**
   * Get a single message by ID
   */
  getById: (id: string) =>
    apiClient.get<Message>(`/messages/${id}`).then((r) => r.data),

  /**
   * Mark a message as read
   */
  markAsRead: (id: string) =>
    apiClient.patch<Message>(`/messages/${id}/read`).then((r) => r.data),

  /**
   * Perform an action on a message (accept, decline, approve, etc.)
   */
  performAction: (id: string, action: MessageActionRequest) =>
    apiClient
      .post<Message>(`/messages/${id}/action`, action)
      .then((r) => r.data),
};
