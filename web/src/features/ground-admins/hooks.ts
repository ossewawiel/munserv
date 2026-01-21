import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import { groundAdminApi } from './api';
import type { GroundAdminStatus } from '@/shared/types/groundAdmin';

/**
 * Query Ground Admins in the current sector
 */
export function useGroundAdmins(status?: GroundAdminStatus) {
  const { admin } = useAuth();
  const sectorId = admin?.sectorId;

  return useQuery({
    queryKey: ['groundAdmins', sectorId, status],
    queryFn: () => groundAdminApi.listInSector(sectorId!, status),
    enabled: !!sectorId,
  });
}

/**
 * Mutation to invite a member to become a Ground Admin
 */
export function useInviteGroundAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      memberId,
      message,
    }: {
      memberId: string;
      message?: string;
    }) => groundAdminApi.invite(memberId, message),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
    },
  });
}

/**
 * Mutation to approve a Ground Admin application
 */
export function useApproveGroundAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      memberId,
      applicationId,
    }: {
      memberId: string;
      applicationId: string;
    }) => groundAdminApi.approve(memberId, applicationId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}

/**
 * Mutation to decline a Ground Admin application
 */
export function useDeclineGroundAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      memberId,
      applicationId,
      reason,
    }: {
      memberId: string;
      applicationId: string;
      reason: string;
    }) => groundAdminApi.decline(memberId, applicationId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}

/**
 * Mutation to revoke Ground Admin status
 */
export function useRevokeGroundAdmin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ memberId, reason }: { memberId: string; reason: string }) =>
      groundAdminApi.revoke(memberId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
    },
  });
}

/**
 * Mutation to update Ground Admin status (active/on_hold)
 */
export function useUpdateGroundAdminStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      memberId,
      status,
    }: {
      memberId: string;
      status: 'active' | 'on_hold';
    }) => groundAdminApi.updateStatus(memberId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
    },
  });
}

/**
 * Mutation to revoke a pending Ground Admin invitation
 */
export function useRevokeGroundAdminInvite() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      memberId,
      applicationId,
    }: {
      memberId: string;
      applicationId: string;
    }) => groundAdminApi.revokeInvite(memberId, applicationId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['groundAdmins'] });
      queryClient.invalidateQueries({ queryKey: ['members'] });
    },
  });
}
