import { useQuery } from '@tanstack/react-query';
import { dashboardApi } from './api';

export function useDashboardStats() {
  return useQuery({
    queryKey: ['dashboard', 'stats'],
    queryFn: () => dashboardApi.getStats(),
  });
}

export function useHeatReport(limit?: number) {
  return useQuery({
    queryKey: ['dashboard', 'heatReport', limit],
    queryFn: () => dashboardApi.getHeatReport(limit),
  });
}
