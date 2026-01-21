import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { groundAdminApi } from './api';
import { mockGroundAdmins } from '@/test/mocks/handlers';

describe('groundAdminApi', () => {
  describe('listInSector', () => {
    it('should fetch all ground admins in sector', async () => {
      const result = await groundAdminApi.listInSector('sector-1');

      expect(result.items).toHaveLength(mockGroundAdmins.length);
      expect(result.total).toBe(mockGroundAdmins.length);
    });

    it('should filter ground admins by status', async () => {
      const result = await groundAdminApi.listInSector('sector-1', 'active');

      expect(result.items.every((ga) => ga.status === 'active')).toBe(true);
    });

    it('should return empty list for sector with no ground admins', async () => {
      server.use(
        http.get('*/sectors/:sectorId/ground-admins', () => {
          return HttpResponse.json({
            items: [],
            total: 0,
          });
        })
      );

      const result = await groundAdminApi.listInSector('sector-empty');

      expect(result.items).toHaveLength(0);
    });
  });

  describe('invite', () => {
    it('should invite a member to become ground admin', async () => {
      const result = await groundAdminApi.invite('member-2', 'Please join us!');

      expect(result.applicationId).toBeDefined();
      expect(result.status).toBe('pending');
    });

    it('should invite without message', async () => {
      const result = await groundAdminApi.invite('member-2');

      expect(result.applicationId).toBeDefined();
      expect(result.status).toBe('pending');
    });

    it('should throw error when member is already a ground admin', async () => {
      await expect(groundAdminApi.invite('member-1')).rejects.toThrow();
    });
  });

  describe('approve', () => {
    it('should approve ground admin application', async () => {
      const result = await groundAdminApi.approve('member-2', 'app-123');

      expect(result.status).toBe('approved');
      expect(result.member).toBeDefined();
      expect(result.member?.isGroundAdmin).toBe(true);
      expect(result.member?.groundAdminStatus).toBe('active');
    });

    it('should throw error for invalid application', async () => {
      server.use(
        http.post('*/members/:memberId/ground-admin/approve', () => {
          return HttpResponse.json(
            { message: 'Invalid application' },
            { status: 400 }
          );
        })
      );

      await expect(
        groundAdminApi.approve('member-2', 'invalid-app')
      ).rejects.toThrow();
    });
  });

  describe('decline', () => {
    it('should decline ground admin application', async () => {
      const result = await groundAdminApi.decline(
        'member-2',
        'app-123',
        'Insufficient experience'
      );

      expect(result.status).toBe('declined');
    });

    it('should throw error for invalid application', async () => {
      server.use(
        http.post('*/members/:memberId/ground-admin/decline', () => {
          return HttpResponse.json(
            { message: 'Invalid application' },
            { status: 400 }
          );
        })
      );

      await expect(
        groundAdminApi.decline('member-2', 'invalid-app', 'Some reason')
      ).rejects.toThrow();
    });
  });

  describe('revoke', () => {
    it('should revoke ground admin status', async () => {
      const result = await groundAdminApi.revoke('member-1', 'Inactive for too long');

      expect(result.status).toBe('revoked');
      expect(result.member).toBeDefined();
      expect(result.member?.isGroundAdmin).toBe(false);
    });

    it('should throw error when member is not a ground admin', async () => {
      await expect(
        groundAdminApi.revoke('member-2', 'Some reason')
      ).rejects.toThrow();
    });
  });

  describe('updateStatus', () => {
    it('should update ground admin status to on_hold', async () => {
      const result = await groundAdminApi.updateStatus('member-1', 'on_hold');

      expect(result.status).toBe('on_hold');
    });

    it('should update ground admin status to active', async () => {
      const result = await groundAdminApi.updateStatus('member-5', 'active');

      expect(result.status).toBe('active');
    });

    it('should throw error when member is not a ground admin', async () => {
      await expect(
        groundAdminApi.updateStatus('member-2', 'on_hold')
      ).rejects.toThrow();
    });
  });
});
