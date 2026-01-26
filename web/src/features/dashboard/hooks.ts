import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import { dashboardApi } from './api';

export function useDashboardStats() {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['dashboard', 'stats', sectorId],
    queryFn: () => dashboardApi.getStats(sectorId!),
    enabled: !!sectorId,
  });
}

export function useHeatReport(limit?: number) {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['dashboard', 'heatReport', sectorId, limit],
    queryFn: () => dashboardApi.getHeatReport(sectorId!, limit),
    enabled: !!sectorId,
  });
}
