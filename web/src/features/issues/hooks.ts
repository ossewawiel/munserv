import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/shared/hooks/useAuth';
import { issueApi } from './api';
import type { IssueFilterParams, IssueState } from './types';

export function useIssues(params?: Omit<IssueFilterParams, 'sectorId'>) {
  const { admin } = useAuth();
  const fullParams: IssueFilterParams = {
    ...params,
    sectorId: admin?.sectorId,
  };

  return useQuery({
    queryKey: ['issues', fullParams],
    queryFn: () => issueApi.getAll(fullParams),
    enabled: !!admin?.sectorId,
  });
}

export function useIssue(id: string) {
  return useQuery({
    queryKey: ['issues', id],
    queryFn: () => issueApi.getById(id),
    enabled: !!id,
  });
}

export function useMyIssues(params?: { page?: number; limit?: number }) {
  return useQuery({
    queryKey: ['issues', 'mine', params],
    queryFn: () => issueApi.getMine(params),
  });
}

export function useUpdateIssueState() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, state, note }: { id: string; state: IssueState; note?: string }) =>
      issueApi.updateState(id, { state, note }),
    onSuccess: (data, { id }) => {
      queryClient.setQueryData(['issues', id], data);
      queryClient.invalidateQueries({ queryKey: ['issues'] });
    },
  });
}
