import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supportAccessApi } from './api';
import type { GrantSupportAccessRequest, SupportGrantStatus } from './types';

/**
 * Query hook for listing support grants, optionally filtered by status
 */
export function useSupportGrants(status?: SupportGrantStatus) {
  return useQuery({
    queryKey: ['support-grants', status ?? 'all'],
    queryFn: () => supportAccessApi.list(status),
  });
}

/**
 * Mutation hook for granting support access
 */
export function useGrantSupportAccess() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (request: GrantSupportAccessRequest) => supportAccessApi.grant(request),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['support-grants'] });
    },
  });
}

/**
 * Mutation hook for revoking a support grant
 */
export function useRevokeSupportGrant() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => supportAccessApi.revoke(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['support-grants'] });
    },
  });
}
