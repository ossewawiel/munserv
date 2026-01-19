import { apiClient } from '@/lib/api-client';
import type {
  SectorSettings,
  SectorSettingsUpdate,
} from '@/shared/types/sectorSettings';

export const sectorSettingsApi = {
  /**
   * Get sector settings (Sector Chief only)
   */
  get: (sectorId: string) =>
    apiClient
      .get<SectorSettings>(`/sectors/${sectorId}/settings`)
      .then((r) => r.data),

  /**
   * Update sector settings (Sector Chief only)
   */
  update: (sectorId: string, settings: SectorSettingsUpdate) =>
    apiClient
      .patch<SectorSettings>(`/sectors/${sectorId}/settings`, settings)
      .then((r) => r.data),
};
