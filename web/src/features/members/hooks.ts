import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import type { MemberStatus } from '@/features/auth/types';
import { membersApi } from './api';

export function useMembers(params?: {
  page?: number;
  limit?: number;
  status?: MemberStatus;
}) {
  const { admin } = useAuth();

  return useQuery({
    queryKey: ['members', admin?.sectorId, params],
    queryFn: () => membersApi.getAll(admin!.sectorId, params),
    enabled: !!admin?.sectorId,
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

  return useQuery({
    queryKey: ['members', 'pending-count', admin?.sectorId],
    queryFn: () => membersApi.getPendingCount(admin!.sectorId),
    enabled: !!admin?.sectorId,
    refetchInterval: 30000, // Refresh every 30 seconds
  });
}
