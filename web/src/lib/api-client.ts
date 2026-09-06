import axios from 'axios';

import { authEvents } from './auth-events';

/**
 * Decodes the `exp` claim (seconds since epoch) from a JWT's base64url
 * payload, without a library. Returns `null` if the token is malformed
 * or has no numeric `exp` claim.
 */
function decodeJwtExpirySeconds(token: string): number | null {
  const parts = token.split('.');
  if (parts.length !== 3) {
    return null;
  }
  try {
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=');
    const payload: unknown = JSON.parse(atob(padded));
    if (
      typeof payload === 'object' &&
      payload !== null &&
      'exp' in payload &&
      typeof (payload as { exp: unknown }).exp === 'number'
    ) {
      return (payload as { exp: number }).exp;
    }
    return null;
  } catch {
    return null;
  }
}

/** True when the stored token's `exp` claim has passed. */
function isTokenExpired(token: string): boolean {
  const expirySeconds = decodeJwtExpirySeconds(token);
  if (expirySeconds === null) {
    return false;
  }
  return expirySeconds * 1000 < Date.now();
}

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3001/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    const requestUrl = error.config?.url ?? '';

    // Handle authentication/authorization errors.
    //
    // This backend has no AuthenticationEntryPoint, so an unauthenticated
    // request (missing or expired token) is denied with 403, not 401
    // (see #117). 401 is reserved for a token Spring Security itself
    // rejects, which in practice does not happen for expired tokens
    // today; the branch is kept for when #117 lands and always ends the
    // session.
    //
    // A 403 with a *valid, current* token means the role lacks
    // permission for this specific request (e.g. a pod admin's dashboard
    // request under #114) and must not end the session, so the caller
    // can show its own error. A 403 ends the session when:
    //   - no access token is stored, or
    //   - the stored token's `exp` claim has passed, or
    //   - a support grant is stored and was revoked/expired (W29).
    const isLoginRequest = requestUrl.includes('/auth/admin/login');
    const isRegisterRequest = requestUrl.includes('/auth/register');
    const accessToken = localStorage.getItem('accessToken');
    const hasSupportGrant = !!localStorage.getItem('supportGrant');
    const hasNoToken = !accessToken;
    const hasExpiredToken = !!accessToken && isTokenExpired(accessToken);

    const shouldEndSession =
      !isLoginRequest &&
      !isRegisterRequest &&
      (status === 401 ||
        (status === 403 && (hasSupportGrant || hasNoToken || hasExpiredToken)));

    if (shouldEndSession) {
      // Clear auth data
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('admin');
      localStorage.removeItem('supportGrant');

      // Emit event for React components to handle
      authEvents.emit('session-expired');
    }
    return Promise.reject(error);
  }
);

// Development-only request/response logging for debugging
if (import.meta.env.DEV) {
  apiClient.interceptors.request.use((config) => {
    console.log(
      `[API Request] ${config.method?.toUpperCase()} ${config.baseURL}${config.url}`
    );
    return config;
  });

  apiClient.interceptors.response.use(
    (response) => {
      console.log(`[API Response] ${response.status} ${response.config.url}`);
      return response;
    },
    (error) => {
      console.error(`[API Error] ${error.message}`, {
        url: error.config?.url,
        baseURL: error.config?.baseURL,
        status: error.response?.status,
        data: error.response?.data,
      });
      return Promise.reject(error);
    }
  );
}
