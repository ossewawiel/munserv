import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import { dashboardApi } from './api';

export function useDashboardStats() {
  const { admin } = useAuth();

  return useQuery({
    queryKey: ['dashboard', 'stats', admin?.sectorId],
    queryFn: () => dashboardApi.getStats(admin!.sectorId),
    enabled: !!admin?.sectorId,
  });
}

export function useHeatReport(limit?: number) {
  const { admin } = useAuth();

  return useQuery({
    queryKey: ['dashboard', 'heatReport', admin?.sectorId, limit],
    queryFn: () => dashboardApi.getHeatReport(admin!.sectorId, limit),
    enabled: !!admin?.sectorId,
  });
}
