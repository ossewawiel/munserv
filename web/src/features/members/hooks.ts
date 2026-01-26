import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import { membersApi } from './api';
import type { MemberFilterParams } from './types';

export function useMembers(params: MemberFilterParams = {}) {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['members', sectorId, params],
    queryFn: () => membersApi.getAll(sectorId!, params),
    enabled: !!sectorId,
  });
}

export function useApproveMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => membersApi.approve(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['members'] });
      queryClient.invalidateQueries({ queryKey: ['members', 'pending-count'] });
    },
  });
}

export function useRejectMember() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => membersApi.reject(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['members'] });
      queryClient.invalidateQueries({ queryKey: ['members', 'pending-count'] });
    },
  });
}

export function usePendingMemberCount() {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['members', 'pending-count', sectorId],
    queryFn: () => membersApi.getPendingCount(sectorId!),
    enabled: !!sectorId,
    refetchInterval: 30000, // Refresh every 30 seconds
  });
}

export function useGARequestsCount() {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['members', 'gaRequestsCount', sectorId],
    queryFn: async () => {
      const response = await membersApi.getAll(sectorId!, {
        hasPendingApplication: true,
        limit: 1,
      });
      return response.pagination.totalItems;
    },
    enabled: !!sectorId,
    refetchInterval: 30000, // Refresh every 30 seconds
  });
}
