import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { verificationApi } from './api';
import type { RequestVerificationRequest } from '@/shared/types/verification';

/**
 * Query verification history for an issue
 */
export function useVerificationHistory(issueId: string) {
  return useQuery({
    queryKey: ['verifications', issueId],
    queryFn: () => verificationApi.getHistory(issueId),
    enabled: !!issueId,
  });
}

/**
 * Mutation to request verification for an issue
 */
export function useRequestVerification() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      issueId,
      request,
    }: {
      issueId: string;
      request: RequestVerificationRequest;
    }) => verificationApi.requestVerification(issueId, request),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['verifications', variables.issueId],
      });
      queryClient.invalidateQueries({
        queryKey: ['issues', variables.issueId],
      });
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
}
