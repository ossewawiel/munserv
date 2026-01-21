import { describe, it, expect, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { membersApi } from './api';

describe('membersApi', () => {
  beforeEach(() => {
    server.resetHandlers();
  });

  describe('getAll', () => {
    it('should fetch all members successfully', async () => {
      const response = await membersApi.getAll('sector-1');

      expect(response.items).toBeDefined();
      expect(response.items).toHaveLength(7); // 7 members in mock data to cover all GA scenarios
      expect(response.pagination).toBeDefined();
    });

    it('should filter members by status', async () => {
      const response = await membersApi.getAll('sector-1', { status: 'pending_approval' });

      expect(response.items).toHaveLength(1);
      expect(response.items[0].status).toBe('pending_approval');
    });

    it('should include status parameter in request URL', async () => {
      let capturedUrl: URL | null = null;

      server.use(
        http.get('*/admin/members', ({ request }) => {
          capturedUrl = new URL(request.url);
          return HttpResponse.json({
            items: [],
            pagination: { page: 1, limit: 20, totalItems: 0, totalPages: 0 },
          });
        })
      );

      await membersApi.getAll('sector-1', { status: 'pending_approval' });

      expect(capturedUrl).not.toBeNull();
      expect(capturedUrl!.searchParams.get('status')).toBe('pending_approval');
      expect(capturedUrl!.searchParams.get('sectorId')).toBe('sector-1');
    });

    it('should not include status parameter when undefined', async () => {
      let capturedUrl: URL | null = null;

      server.use(
        http.get('*/admin/members', ({ request }) => {
          capturedUrl = new URL(request.url);
          return HttpResponse.json({
            items: [],
            pagination: { page: 1, limit: 20, totalItems: 0, totalPages: 0 },
          });
        })
      );

      await membersApi.getAll('sector-1', { status: undefined });

      expect(capturedUrl).not.toBeNull();
      expect(capturedUrl!.searchParams.has('status')).toBe(false);
      expect(capturedUrl!.searchParams.get('sectorId')).toBe('sector-1');
    });

    it('should handle pagination parameters', async () => {
      const response = await membersApi.getAll('sector-1', { page: 2, limit: 10 });

      expect(response.pagination.page).toBe(2);
      expect(response.pagination.limit).toBe(10);
    });

    it('should return empty list when no members', async () => {
      server.use(
        http.get('*/admin/members', () => {
          return HttpResponse.json({
            items: [],
            pagination: {
              page: 1,
              limit: 20,
              totalItems: 0,
              totalPages: 0,
            },
          });
        })
      );

      const response = await membersApi.getAll('sector-1');
      expect(response.items).toHaveLength(0);
    });

    it('should throw error on server failure', async () => {
      server.use(
        http.get('*/admin/members', () => {
          return HttpResponse.json(
            { message: 'Internal server error' },
            { status: 500 }
          );
        })
      );

      await expect(membersApi.getAll('sector-1')).rejects.toThrow();
    });

    it('should filter by isGroundAdmin', async () => {
      const response = await membersApi.getAll('sector-1', { isGroundAdmin: true });

      // Should return members 1 and 7 (both have isGroundAdmin: true)
      expect(response.items.every((m) => m.isGroundAdmin === true)).toBe(true);
      expect(response.items.length).toBeGreaterThan(0);
    });

    it('should pass isGroundAdmin as query parameter', async () => {
      let capturedUrl: URL | null = null;

      server.use(
        http.get('*/admin/members', ({ request }) => {
          capturedUrl = new URL(request.url);
          return HttpResponse.json({
            items: [],
            pagination: { page: 1, limit: 20, totalItems: 0, totalPages: 0 },
          });
        })
      );

      await membersApi.getAll('sector-1', { isGroundAdmin: true });

      expect(capturedUrl).not.toBeNull();
      expect(capturedUrl!.searchParams.get('isGroundAdmin')).toBe('true');
    });

    it('should filter by hasPendingApplication', async () => {
      const response = await membersApi.getAll('sector-1', { hasPendingApplication: true });

      // Should return member 5 (has hasPendingApplication: true)
      expect(response.items.every((m) => m.hasPendingApplication === true)).toBe(true);
      expect(response.items.length).toBeGreaterThan(0);
    });

    it('should pass hasPendingApplication as query parameter', async () => {
      let capturedUrl: URL | null = null;

      server.use(
        http.get('*/admin/members', ({ request }) => {
          capturedUrl = new URL(request.url);
          return HttpResponse.json({
            items: [],
            pagination: { page: 1, limit: 20, totalItems: 0, totalPages: 0 },
          });
        })
      );

      await membersApi.getAll('sector-1', { hasPendingApplication: true });

      expect(capturedUrl).not.toBeNull();
      expect(capturedUrl!.searchParams.get('hasPendingApplication')).toBe('true');
    });

    it('should filter by hasInvitationPending', async () => {
      const response = await membersApi.getAll('sector-1', { hasInvitationPending: true });

      // Should return member 6 (has hasInvitationPending: true)
      expect(response.items.every((m) => m.hasInvitationPending === true)).toBe(true);
      expect(response.items.length).toBeGreaterThan(0);
    });

    it('should pass hasInvitationPending as query parameter', async () => {
      let capturedUrl: URL | null = null;

      server.use(
        http.get('*/admin/members', ({ request }) => {
          capturedUrl = new URL(request.url);
          return HttpResponse.json({
            items: [],
            pagination: { page: 1, limit: 20, totalItems: 0, totalPages: 0 },
          });
        })
      );

      await membersApi.getAll('sector-1', { hasInvitationPending: true });

      expect(capturedUrl).not.toBeNull();
      expect(capturedUrl!.searchParams.get('hasInvitationPending')).toBe('true');
    });
  });

  describe('approve', () => {
    it('should approve a pending member successfully', async () => {
      const response = await membersApi.approve('member-2');

      expect(response).toEqual({
        memberId: 'member-2',
        email: 'jane@example.com',
        message: 'Member approved successfully',
      });
    });

    it('should handle member not found error', async () => {
      await expect(membersApi.approve('non-existent-id')).rejects.toMatchObject({
        response: { status: 404 },
      });
    });

    it('should handle wrong status error', async () => {
      // member-1 is active, not pending_approval
      await expect(membersApi.approve('member-1')).rejects.toMatchObject({
        response: { status: 400 },
      });
    });

    it('should throw error on server failure', async () => {
      server.use(
        http.post('*/admin/members/:id/approve', () => {
          return HttpResponse.json(
            { message: 'Internal server error' },
            { status: 500 }
          );
        })
      );

      await expect(membersApi.approve('member-2')).rejects.toThrow();
    });
  });

  describe('reject', () => {
    it('should reject/delete a member successfully', async () => {
      const response = await membersApi.reject('member-2');
      expect(response.status).toBe(204);
    });

    it('should handle member not found error', async () => {
      await expect(membersApi.reject('non-existent-id')).rejects.toMatchObject({
        response: { status: 404 },
      });
    });

    it('should throw error on server failure', async () => {
      server.use(
        http.delete('*/admin/members/:id', () => {
          return HttpResponse.json(
            { message: 'Internal server error' },
            { status: 500 }
          );
        })
      );

      await expect(membersApi.reject('member-1')).rejects.toThrow();
    });
  });

  describe('getPendingCount', () => {
    it('should fetch pending member count successfully', async () => {
      const count = await membersApi.getPendingCount('sector-1');
      expect(count).toBe(1); // Only member-2 is pending_approval in mock data
    });

    it('should return 0 when no pending members', async () => {
      server.use(
        http.get('*/admin/members/pending-count', () => {
          return HttpResponse.json({ count: 0 });
        })
      );

      const count = await membersApi.getPendingCount('sector-1');
      expect(count).toBe(0);
    });

    it('should throw error on server failure', async () => {
      server.use(
        http.get('*/admin/members/pending-count', () => {
          return HttpResponse.json(
            { message: 'Internal server error' },
            { status: 500 }
          );
        })
      );

      await expect(membersApi.getPendingCount('sector-1')).rejects.toThrow();
    });
  });
});
