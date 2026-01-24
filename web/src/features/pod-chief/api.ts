import { apiClient } from '@/lib/api-client';
import type {
  PodDashboardStats,
  WardDashboardStats,
  SectorDashboardStats,
} from './types';

/**
 * Pod Chief API functions
 * Endpoints require POD_CHIEF role
 */
export const podChiefApi = {
  /**
   * Get pod-level dashboard statistics
   * GET /api/v1/pod/dashboard
   */
  getDashboard: () =>
    apiClient.get<PodDashboardStats>('/pod/dashboard').then((r) => r.data),

  /**
   * Get ward-level dashboard statistics
   * GET /api/v1/pod/dashboard/wards/{wardId}
   */
  getWardDashboard: (wardId: string) =>
    apiClient
      .get<WardDashboardStats>(`/pod/dashboard/wards/${wardId}`)
      .then((r) => r.data),

  /**
   * Get sector-level dashboard statistics
   * GET /api/v1/pod/dashboard/sectors/{sectorId}
   */
  getSectorDashboard: (sectorId: string) =>
    apiClient
      .get<SectorDashboardStats>(`/pod/dashboard/sectors/${sectorId}`)
      .then((r) => r.data),
};
