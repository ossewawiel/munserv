import { http, HttpResponse } from 'msw';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

import { server } from '@/test/mocks/server';

import { apiClient } from './api-client';
import { authEvents } from './auth-events';

const TEST_URL = 'http://localhost:3001/api/v1/pod/dashboard';

describe('apiClient response interceptor', () => {
  beforeEach(() => {
    localStorage.clear();
    localStorage.setItem('accessToken', 'token');
    localStorage.setItem('refreshToken', 'refresh');
    localStorage.setItem('admin', JSON.stringify({ id: 'admin-1' }));
  });

  afterEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });

  it('should not end the session on a 403 without a support grant', async () => {
    server.use(
      http.get(TEST_URL, () => new HttpResponse(null, { status: 403 }))
    );
    const listener = vi.fn();
    const unsubscribe = authEvents.subscribe(listener);

    await expect(apiClient.get('/pod/dashboard')).rejects.toBeDefined();

    expect(listener).not.toHaveBeenCalled();
    expect(localStorage.getItem('accessToken')).toBe('token');

    unsubscribe();
  });

  it('should end the session on a 403 under a support grant', async () => {
    localStorage.setItem(
      'supportGrant',
      JSON.stringify({ grantedRole: 'super_user', expiresAt: '2099-01-01T00:00:00Z' })
    );
    server.use(
      http.get(TEST_URL, () => new HttpResponse(null, { status: 403 }))
    );
    const listener = vi.fn();
    const unsubscribe = authEvents.subscribe(listener);

    await expect(apiClient.get('/pod/dashboard')).rejects.toBeDefined();

    expect(listener).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'session-expired' })
    );
    expect(localStorage.getItem('accessToken')).toBeNull();

    unsubscribe();
  });

  it('should end the session on a 401', async () => {
    server.use(
      http.get(TEST_URL, () => new HttpResponse(null, { status: 401 }))
    );
    const listener = vi.fn();
    const unsubscribe = authEvents.subscribe(listener);

    await expect(apiClient.get('/pod/dashboard')).rejects.toBeDefined();

    expect(listener).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'session-expired' })
    );
    expect(localStorage.getItem('accessToken')).toBeNull();

    unsubscribe();
  });
});
