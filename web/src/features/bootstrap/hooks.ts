import { useMutation } from '@tanstack/react-query';

import { bootstrapApi } from './api';
import type { CreatePodChiefRequest } from './types';

/**
 * Hook for creating the first Pod Chief during bootstrap.
 * Used by super user to create the initial Pod Chief account.
 */
export function useCreatePodChief() {
  return useMutation({
    mutationFn: (request: CreatePodChiefRequest) => bootstrapApi.createPodChief(request),
  });
}
