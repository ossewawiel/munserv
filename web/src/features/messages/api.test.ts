import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { messagesApi } from './api';
import { mockMessages } from '@/test/mocks/handlers';

describe('messagesApi', () => {
  describe('getAll', () => {
    it('should fetch all messages', async () => {
      const result = await messagesApi.getAll();

      expect(result.items).toHaveLength(mockMessages.length);
      expect(result.unreadCount).toBe(2); // msg-1 and msg-2 are unread
      expect(result.total).toBe(mockMessages.length);
    });

    it('should filter messages by status', async () => {
      const result = await messagesApi.getAll({ status: 'unread' });

      expect(result.items.every((m) => m.status === 'unread')).toBe(true);
    });

    it('should support pagination parameters', async () => {
      const result = await messagesApi.getAll({ page: 2, size: 10 });

      expect(result.page).toBe(2);
    });
  });

  describe('getById', () => {
    it('should fetch a single message by id', async () => {
      const result = await messagesApi.getById('msg-1');

      expect(result.id).toBe('msg-1');
      expect(result.type).toBe('ground_admin_application');
      expect(result.title).toBe('Ground Admin Application');
    });

    it('should throw error for non-existent message', async () => {
      server.use(
        http.get('*/messages/:id', () => {
          return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
        })
      );

      await expect(messagesApi.getById('non-existent')).rejects.toThrow();
    });
  });

  describe('markAsRead', () => {
    it('should mark message as read and return updated message', async () => {
      const result = await messagesApi.markAsRead('msg-1');

      expect(result.status).toBe('read');
      expect(result.readAt).toBeDefined();
    });

    it('should throw error for non-existent message', async () => {
      server.use(
        http.patch('*/messages/:id/read', () => {
          return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
        })
      );

      await expect(messagesApi.markAsRead('non-existent')).rejects.toThrow();
    });
  });

  describe('performAction', () => {
    it('should perform action on message and return updated message', async () => {
      const result = await messagesApi.performAction('msg-1', {
        action: 'approve',
        note: 'Good candidate',
      });

      expect(result.status).toBe('actioned');
      expect(result.actionResult).toBe('approve');
      expect(result.actionedAt).toBeDefined();
    });

    it('should throw error when message already actioned', async () => {
      server.use(
        http.post('*/messages/:id/action', () => {
          return HttpResponse.json({ message: 'Message already actioned' }, { status: 409 });
        })
      );

      await expect(
        messagesApi.performAction('msg-4', { action: 'acknowledge' })
      ).rejects.toThrow();
    });

    it('should throw error for non-existent message', async () => {
      server.use(
        http.post('*/messages/:id/action', () => {
          return HttpResponse.json({ message: 'Message not found' }, { status: 404 });
        })
      );

      await expect(
        messagesApi.performAction('non-existent', { action: 'approve' })
      ).rejects.toThrow();
    });
  });
});
