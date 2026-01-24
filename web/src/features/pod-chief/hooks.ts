import { useQuery } from '@tanstack/react-query';
import { podChiefApi } from './api';

/**
 * Query keys for pod-chief feature
 */
export const podChiefKeys = {
  all: ['pod-chief'] as const,
  dashboard: () => [...podChiefKeys.all, 'dashboard'] as const,
  wardDashboard: (wardId: string) =>
    [...podChiefKeys.all, 'dashboard', 'ward', wardId] as const,
  sectorDashboard: (sectorId: string) =>
    [...podChiefKeys.all, 'dashboard', 'sector', sectorId] as const,
};

/**
 * Hook to fetch pod-level dashboard statistics
 * For Pod Chief users only
 */
export function usePodDashboard() {
  return useQuery({
    queryKey: podChiefKeys.dashboard(),
    queryFn: podChiefApi.getDashboard,
  });
}

/**
 * Hook to fetch ward-level dashboard statistics
 * @param wardId - The ward UUID to fetch stats for
 */
export function useWardDashboard(wardId: string) {
  return useQuery({
    queryKey: podChiefKeys.wardDashboard(wardId),
    queryFn: () => podChiefApi.getWardDashboard(wardId),
    enabled: !!wardId,
  });
}

/**
 * Hook to fetch sector-level dashboard statistics
 * @param sectorId - The sector UUID to fetch stats for
 */
export function useSectorDashboard(sectorId: string) {
  return useQuery({
    queryKey: podChiefKeys.sectorDashboard(sectorId),
    queryFn: () => podChiefApi.getSectorDashboard(sectorId),
    enabled: !!sectorId,
  });
}
