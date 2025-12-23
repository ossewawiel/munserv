import { apiClient } from '@/lib/api-client';
import type { DashboardStats, HeatReport } from './types';

export const dashboardApi = {
  getStats: () =>
    apiClient.get<DashboardStats>('/admin/dashboard').then((r) => r.data),

  getHeatReport: (limit?: number) =>
    apiClient
      .get<HeatReport>('/admin/reports/heat', { params: { limit } })
      .then((r) => r.data),
};
