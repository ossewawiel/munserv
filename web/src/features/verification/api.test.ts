import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { verificationApi } from './api';

describe('verificationApi', () => {
  describe('requestVerification', () => {
    it('should request existence verification', async () => {
      const result = await verificationApi.requestVerification('issue-1', {
        type: 'existence',
      });

      expect(result.id).toBeDefined();
      expect(result.issueId).toBe('issue-1');
      expect(result.verificationType).toBe('existence');
      expect(result.status).toBe('pending');
    });

    it('should request fix verification', async () => {
      const result = await verificationApi.requestVerification('issue-1', {
        type: 'fix',
      });

      expect(result.verificationType).toBe('fix');
    });

    it('should assign to specific ground admin', async () => {
      const result = await verificationApi.requestVerification('issue-1', {
        type: 'existence',
        assignTo: 'member-1',
      });

      expect(result.assignedTo).toBe('member-1');
    });

    it('should include optional message', async () => {
      const result = await verificationApi.requestVerification('issue-1', {
        type: 'existence',
        message: 'Please verify urgently',
      });

      expect(result.id).toBeDefined();
    });

    it('should throw error for invalid issue', async () => {
      server.use(
        http.post('*/issues/:issueId/request-verification', () => {
          return HttpResponse.json({ message: 'Issue not found' }, { status: 404 });
        })
      );

      await expect(
        verificationApi.requestVerification('invalid-issue', { type: 'existence' })
      ).rejects.toThrow();
    });

    it('should throw error for invalid state', async () => {
      server.use(
        http.post('*/issues/:issueId/request-verification', () => {
          return HttpResponse.json(
            { message: 'Issue must be in REPORTED state' },
            { status: 400 }
          );
        })
      );

      await expect(
        verificationApi.requestVerification('issue-1', { type: 'existence' })
      ).rejects.toThrow();
    });
  });

  describe('getHistory', () => {
    it('should get verification history for issue', async () => {
      const result = await verificationApi.getHistory('issue-1');

      expect(result.items).toBeDefined();
      expect(Array.isArray(result.items)).toBe(true);
    });

    it('should return verifications for the correct issue', async () => {
      const result = await verificationApi.getHistory('issue-1');

      // All returned verifications should be for issue-1
      const verifications = result.items;
      if (verifications.length > 0) {
        expect(verifications[0].issueId).toBe('issue-1');
      }
    });

    it('should return empty array for issue with no verifications', async () => {
      const result = await verificationApi.getHistory('issue-no-verifications');

      expect(result.items).toHaveLength(0);
    });

    it('should throw error for invalid issue', async () => {
      server.use(
        http.get('*/issues/:issueId/verifications', () => {
          return HttpResponse.json({ message: 'Issue not found' }, { status: 404 });
        })
      );

      await expect(verificationApi.getHistory('invalid-issue')).rejects.toThrow();
    });
  });
});
