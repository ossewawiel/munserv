import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import { sectorSettingsApi } from './api';
import type { SectorSettingsUpdate } from '@/shared/types/sectorSettings';

/**
 * Query sector settings for the current admin's sector
 */
export function useSectorSettings() {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['sectorSettings', sectorId],
    queryFn: () => sectorSettingsApi.get(sectorId!),
    enabled: !!sectorId,
  });
}

/**
 * Mutation to update sector settings
 */
export function useUpdateSectorSettings() {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (settings: SectorSettingsUpdate) =>
      sectorSettingsApi.update(sectorId!, settings),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sectorSettings', sectorId] });
    },
  });
}
