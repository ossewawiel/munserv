import { apiClient } from '@/lib/api-client';
import type { DashboardStats, HeatReport } from './types';

export const dashboardApi = {
  getStats: (sectorId: string) =>
    apiClient
      .get<DashboardStats>('/admin/dashboard', { params: { sectorId } })
      .then((r) => r.data),

  getHeatReport: (sectorId: string, limit?: number) =>
    apiClient
      .get<HeatReport>('/admin/reports/heat', { params: { sectorId, limit } })
      .then((r) => r.data),
};
