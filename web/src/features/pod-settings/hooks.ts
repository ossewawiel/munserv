import { useQuery, useMutation, useQueryClient, type UseQueryResult, type UseMutationResult } from '@tanstack/react-query';
import { podSettingsApi } from './api';
import type { PodSettings, UpdatePodSettingsRequest } from './types';

export const podSettingsKeys = {
  all: ['pod', 'settings'] as const,
};

interface UsePodSettingsOptions {
  enabled?: boolean;
}

export function usePodSettings(options?: UsePodSettingsOptions): UseQueryResult<PodSettings> {
  return useQuery({
    queryKey: podSettingsKeys.all,
    queryFn: () => podSettingsApi.getSettings(),
    retry: false,
    enabled: options?.enabled ?? true,
  });
}

export function useUpdatePodSettings(): UseMutationResult<
  PodSettings,
  Error,
  UpdatePodSettingsRequest
> {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (request: UpdatePodSettingsRequest) => podSettingsApi.updateSettings(request),
    onSuccess: (response) => {
      queryClient.setQueryData(podSettingsKeys.all, response);
    },
  });
}
