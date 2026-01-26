import { apiClient } from '@/lib/api-client';
import type { CreatePodChiefRequest, CreatePodChiefResponse } from './types';

export const bootstrapApi = {
  /**
   * Create the first Pod Chief for a pod during bootstrap.
   * Requires super user authentication.
   */
  createPodChief: (request: CreatePodChiefRequest) =>
    apiClient.post<CreatePodChiefResponse>('/bootstrap/pod-chief', request).then((r) => r.data),
};
