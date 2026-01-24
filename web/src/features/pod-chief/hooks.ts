import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { podChiefApi } from './api';
import type {
  CreatePodAdministratorRequest,
  UpdatePodAdministratorRequest,
} from './types';

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
  administrators: () => [...podChiefKeys.all, 'administrators'] as const,
  administrator: (id: string) => [...podChiefKeys.all, 'administrators', id] as const,
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

// ============================================
// Pod Administrators Hooks
// ============================================

/**
 * Hook to fetch all administrators in the pod
 */
export function usePodAdministrators() {
  return useQuery({
    queryKey: podChiefKeys.administrators(),
    queryFn: () => podChiefApi.listAdministrators(),
  });
}

/**
 * Hook to fetch a single administrator by ID
 * @param id - The administrator UUID
 */
export function usePodAdministrator(id: string) {
  return useQuery({
    queryKey: podChiefKeys.administrator(id),
    queryFn: () => podChiefApi.getAdministrator(id),
    enabled: !!id,
  });
}

/**
 * Hook to create a new pod administrator
 */
export function useCreatePodAdministrator() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (request: CreatePodAdministratorRequest) =>
      podChiefApi.createAdministrator(request),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: podChiefKeys.administrators() });
    },
  });
}

/**
 * Hook to update an existing pod administrator
 */
export function useUpdatePodAdministrator() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, request }: { id: string; request: UpdatePodAdministratorRequest }) =>
      podChiefApi.updateAdministrator(id, request),
    onSuccess: (data) => {
      queryClient.setQueryData(podChiefKeys.administrator(data.id), data);
      queryClient.invalidateQueries({ queryKey: podChiefKeys.administrators() });
    },
  });
}

/**
 * Hook to delete (soft delete) a pod administrator
 */
export function useDeletePodAdministrator() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => podChiefApi.deleteAdministrator(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: podChiefKeys.administrators() });
    },
  });
}
