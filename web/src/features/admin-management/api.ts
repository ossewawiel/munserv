import { apiClient } from '@/lib/api-client';
import type {
  Admin,
  AdminCreatedResponse,
  AdminListResponse,
  CreateAdminRequest,
  UpdateAdminRequest,
} from './types';

export const adminManagementApi = {
  /**
   * List admins in the current sector
   */
  list: () =>
    apiClient.get<AdminListResponse>('/admins').then((r) => r.data),

  /**
   * Get a single admin by ID
   */
  get: (id: string) =>
    apiClient.get<Admin>(`/admins/${id}`).then((r) => r.data),

  /**
   * Create a new admin
   */
  create: (request: CreateAdminRequest) =>
    apiClient.post<AdminCreatedResponse>('/admins', request).then((r) => r.data),

  /**
   * Update an existing admin
   */
  update: (id: string, request: UpdateAdminRequest) =>
    apiClient.patch<Admin>(`/admins/${id}`, request).then((r) => r.data),

  /**
   * Soft delete an admin
   */
  delete: (id: string) =>
    apiClient.delete(`/admins/${id}`).then((r) => r.data),
};
