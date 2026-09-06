import { apiClient } from '@/lib/api-client';
import type { PodSettings, UpdatePodSettingsRequest } from './types';

export const podSettingsApi = {
  /**
   * Fetch the current pod's settings: name, server-derived displayName and logoUrl.
   */
  getSettings: () => apiClient.get<PodSettings>('/pod/settings').then((r) => r.data),

  /**
   * Update the pod's name and/or logoUrl. Only the changed fields are sent.
   */
  updateSettings: (request: UpdatePodSettingsRequest) =>
    apiClient.patch<PodSettings>('/pod/settings', request).then((r) => r.data),
};
