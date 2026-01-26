/**
 * Request payload for creating a Pod Chief during bootstrap.
 */
export interface CreatePodChiefRequest {
  email: string;
  displayName: string;
}

/**
 * Response from successful Pod Chief creation.
 */
export interface CreatePodChiefResponse {
  id: string;
  email: string;
  displayName: string;
  role: string;
  temporaryPassword: string;
  createdAt: string;
}
