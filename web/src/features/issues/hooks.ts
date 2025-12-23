import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { issueApi } from './api';
import type { IssueFilterParams, IssueState } from './types';

export function useIssues(params?: IssueFilterParams) {
  return useQuery({
    queryKey: ['issues', params],
    queryFn: () => issueApi.getAll(params),
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
      issueApi.updateState(id, { state, notes: note }),
    onSuccess: (data, { id }) => {
      queryClient.setQueryData(['issues', id], data);
      queryClient.invalidateQueries({ queryKey: ['issues'] });
    },
  });
}
