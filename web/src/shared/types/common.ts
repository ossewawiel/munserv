/**
 * Geographic point with latitude and longitude
 */
export interface GeoPoint {
  latitude: number;
  longitude: number;
}

/**
 * Paginated response wrapper for list endpoints
 */
export interface PaginatedResponse<T> {
  items: T[];
  pagination: {
    page: number;
    limit: number;
    totalItems: number;
    totalPages: number;
  };
}

/**
 * API error response structure
 */
export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

/**
 * Result type for handling success/error states
 */
export type Result<T, E = ApiError> =
  | { success: true; data: T }
  | { success: false; error: E };
