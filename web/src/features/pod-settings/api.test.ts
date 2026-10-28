import { describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { podSettingsApi } from './api';
import { mockPodSettings } from '@/test/mocks/handlers';

describe('podSettingsApi', () => {
  describe('getSettings', () => {
    it('should return the pod settings', async () => {
      const result = await podSettingsApi.getSettings();

      expect(result.name).toBe(mockPodSettings.name);
      expect(result.displayName).toBe(mockPodSettings.displayName);
      expect(result.logoUrl).toBe(mockPodSettings.logoUrl);
    });
  });

  describe('updateSettings', () => {
    it('should send only the changed fields when updating', async () => {
      let receivedBody: unknown;
      server.use(
        http.patch('*/pod/settings', async ({ request }) => {
          receivedBody = await request.json();
          return HttpResponse.json({
            name: 'Ward 42',
            displayName: 'Munserv Pod Ward 42',
            logoUrl: mockPodSettings.logoUrl,
          });
        })
      );

      const result = await podSettingsApi.updateSettings({ name: 'Ward 42' });

      expect(receivedBody).toEqual({ name: 'Ward 42' });
      expect(result.displayName).toBe('Munserv Pod Ward 42');
    });
  });
});
