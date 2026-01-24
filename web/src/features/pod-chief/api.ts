import { apiClient } from '@/lib/api-client';
import type {
  PodDashboardStats,
  WardDashboardStats,
  SectorDashboardStats,
  PodAdministrator,
  PodAdministratorListResponse,
  PodAdministratorCreatedResponse,
  CreatePodAdministratorRequest,
  UpdatePodAdministratorRequest,
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

  // ============================================
  // Pod Administrators API
  // ============================================

  /**
   * List all administrators in the pod
   * GET /api/v1/pod/administrators
   */
  listAdministrators: () =>
    apiClient
      .get<PodAdministratorListResponse>('/pod/administrators')
      .then((r) => r.data),

  /**
   * Get a single administrator by ID
   * GET /api/v1/pod/administrators/{id}
   */
  getAdministrator: (id: string) =>
    apiClient.get<PodAdministrator>(`/pod/administrators/${id}`).then((r) => r.data),

  /**
   * Create a new pod administrator
   * POST /api/v1/pod/administrators
   */
  createAdministrator: (request: CreatePodAdministratorRequest) =>
    apiClient
      .post<PodAdministratorCreatedResponse>('/pod/administrators', request)
      .then((r) => r.data),

  /**
   * Update an existing administrator
   * PATCH /api/v1/pod/administrators/{id}
   */
  updateAdministrator: (id: string, request: UpdatePodAdministratorRequest) =>
    apiClient
      .patch<PodAdministrator>(`/pod/administrators/${id}`, request)
      .then((r) => r.data),

  /**
   * Delete (soft delete) an administrator
   * DELETE /api/v1/pod/administrators/{id}
   */
  deleteAdministrator: (id: string) =>
    apiClient.delete(`/pod/administrators/${id}`).then((r) => r.data),
};
