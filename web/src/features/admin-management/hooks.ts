import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminManagementApi } from './api';
import type { CreateAdminRequest, UpdateAdminRequest } from './types';

/**
 * Query hook for listing admins in the current sector
 */
export function useAdmins() {
  return useQuery({
    queryKey: ['admins'],
    queryFn: () => adminManagementApi.list(),
  });
}

/**
 * Query hook for getting a single admin by ID
 */
export function useAdmin(id: string) {
  return useQuery({
    queryKey: ['admins', id],
    queryFn: () => adminManagementApi.get(id),
    enabled: !!id,
  });
}

/**
 * Mutation hook for creating a new admin
 */
export function useCreateAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (request: CreateAdminRequest) => adminManagementApi.create(request),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admins'] });
    },
  });
}

/**
 * Mutation hook for updating an existing admin
 */
export function useUpdateAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, request }: { id: string; request: UpdateAdminRequest }) =>
      adminManagementApi.update(id, request),
    onSuccess: (data) => {
      queryClient.setQueryData(['admins', data.id], data);
      queryClient.invalidateQueries({ queryKey: ['admins'] });
    },
  });
}

/**
 * Mutation hook for deleting an admin
 */
export function useDeleteAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => adminManagementApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admins'] });
    },
  });
}
