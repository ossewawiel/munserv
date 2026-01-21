import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { sectorSettingsApi } from './api';
import { mockSectorSettings } from '@/test/mocks/handlers';

describe('sectorSettingsApi', () => {
  describe('get', () => {
    it('should fetch sector settings', async () => {
      const result = await sectorSettingsApi.get('sector-1');

      expect(result.sectorId).toBe('sector-1');
      expect(result.newIssueVerificationMode).toBe(
        mockSectorSettings.newIssueVerificationMode
      );
      expect(result.fixVerificationMode).toBe(mockSectorSettings.fixVerificationMode);
      expect(result.daysFixedBeforeClosed).toBe(mockSectorSettings.daysFixedBeforeClosed);
      expect(result.minimumGroundAdmins).toBe(mockSectorSettings.minimumGroundAdmins);
    });

    it('should return settings for any sector', async () => {
      const result = await sectorSettingsApi.get('sector-other');

      expect(result.sectorId).toBe('sector-other');
    });

    it('should throw error for unauthorized access', async () => {
      server.use(
        http.get('*/sectors/:sectorId/settings', () => {
          return HttpResponse.json({ message: 'Forbidden' }, { status: 403 });
        })
      );

      await expect(sectorSettingsApi.get('sector-1')).rejects.toThrow();
    });

    it('should throw error for not found', async () => {
      server.use(
        http.get('*/sectors/:sectorId/settings', () => {
          return HttpResponse.json({ message: 'Not found' }, { status: 404 });
        })
      );

      await expect(sectorSettingsApi.get('invalid-sector')).rejects.toThrow();
    });
  });

  describe('update', () => {
    it('should update newIssueVerificationMode', async () => {
      const result = await sectorSettingsApi.update('sector-1', {
        newIssueVerificationMode: 'admin_assigns',
      });

      expect(result.newIssueVerificationMode).toBe('admin_assigns');
    });

    it('should update fixVerificationMode', async () => {
      const result = await sectorSettingsApi.update('sector-1', {
        fixVerificationMode: 'first_come',
      });

      expect(result.fixVerificationMode).toBe('first_come');
    });

    it('should update daysFixedBeforeClosed', async () => {
      const result = await sectorSettingsApi.update('sector-1', {
        daysFixedBeforeClosed: 14,
      });

      expect(result.daysFixedBeforeClosed).toBe(14);
    });

    it('should update minimumGroundAdmins', async () => {
      const result = await sectorSettingsApi.update('sector-1', {
        minimumGroundAdmins: 5,
      });

      expect(result.minimumGroundAdmins).toBe(5);
    });

    it('should update multiple settings at once', async () => {
      const result = await sectorSettingsApi.update('sector-1', {
        newIssueVerificationMode: 'nearest_auto',
        fixVerificationMode: 'all_notified',
        daysFixedBeforeClosed: 10,
        minimumGroundAdmins: 4,
      });

      expect(result.newIssueVerificationMode).toBe('nearest_auto');
      expect(result.fixVerificationMode).toBe('all_notified');
      expect(result.daysFixedBeforeClosed).toBe(10);
      expect(result.minimumGroundAdmins).toBe(4);
    });

    it('should return updated timestamp', async () => {
      const before = new Date().toISOString();
      const result = await sectorSettingsApi.update('sector-1', {
        daysFixedBeforeClosed: 7,
      });

      expect(result.updatedAt).toBeDefined();
      expect(new Date(result.updatedAt) >= new Date(before)).toBe(true);
    });

    it('should throw error for invalid daysFixedBeforeClosed value (too low)', async () => {
      await expect(
        sectorSettingsApi.update('sector-1', {
          daysFixedBeforeClosed: 0,
        })
      ).rejects.toThrow();
    });

    it('should throw error for invalid daysFixedBeforeClosed value (too high)', async () => {
      await expect(
        sectorSettingsApi.update('sector-1', {
          daysFixedBeforeClosed: 100,
        })
      ).rejects.toThrow();
    });

    it('should throw error for invalid minimumGroundAdmins value (negative)', async () => {
      await expect(
        sectorSettingsApi.update('sector-1', {
          minimumGroundAdmins: -1,
        })
      ).rejects.toThrow();
    });

    it('should throw error for invalid minimumGroundAdmins value (too high)', async () => {
      await expect(
        sectorSettingsApi.update('sector-1', {
          minimumGroundAdmins: 100,
        })
      ).rejects.toThrow();
    });

    it('should throw error for forbidden access', async () => {
      server.use(
        http.patch('*/sectors/:sectorId/settings', () => {
          return HttpResponse.json({ message: 'Forbidden' }, { status: 403 });
        })
      );

      await expect(
        sectorSettingsApi.update('sector-1', { daysFixedBeforeClosed: 7 })
      ).rejects.toThrow();
    });
  });
});
