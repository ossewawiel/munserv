import axios from 'axios';

import { authEvents } from './auth-events';

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

    // Handle authentication/authorization errors
    // 401 = Invalid/expired token: always ends the session.
    // 403 = Access denied for the current role: this is a normal, expected
    // response for callers that probe a permission (e.g. a pod dashboard
    // request from a pod admin) and must not end the session. The one
    // exception is a support user acting under a support grant (W29): a
    // 403 there means the grant was revoked or expired, so the session
    // ends.
    const isLoginRequest = requestUrl.includes('/auth/admin/login');
    const isRegisterRequest = requestUrl.includes('/auth/register');
    const hasSupportGrant = !!localStorage.getItem('supportGrant');

    const shouldEndSession =
      !isLoginRequest &&
      !isRegisterRequest &&
      (status === 401 || (status === 403 && hasSupportGrant));

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
