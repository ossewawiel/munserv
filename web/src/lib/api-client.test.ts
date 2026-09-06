import { http, HttpResponse } from 'msw';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

import { server } from '@/test/mocks/server';

import { apiClient } from './api-client';
import { authEvents } from './auth-events';

const TEST_URL = 'http://localhost:3001/api/v1/pod/dashboard';

/** Builds an unsigned JWT with the given payload, for exp-claim tests only. */
function makeJwt(payload: Record<string, unknown>): string {
  const toBase64Url = (obj: Record<string, unknown>): string =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  return `${toBase64Url({ alg: 'none', typ: 'JWT' })}.${toBase64Url(payload)}.signature`;
}

describe('apiClient response interceptor', () => {
  beforeEach(() => {
    const validToken = makeJwt({ sub: 'admin-1', exp: Math.floor(Date.now() / 1000) + 3600 });
    localStorage.clear();
    localStorage.setItem('accessToken', validToken);
    localStorage.setItem('refreshToken', 'refresh');
    localStorage.setItem('admin', JSON.stringify({ id: 'admin-1' }));
  });

  afterEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });

  it('should not end the session on a 403 without a support grant', async () => {
    const validToken = localStorage.getItem('accessToken');
    server.use(
      http.get(TEST_URL, () => new HttpResponse(null, { status: 403 }))
    );
    const listener = vi.fn();
    const unsubscribe = authEvents.subscribe(listener);

    await expect(apiClient.get('/pod/dashboard')).rejects.toBeDefined();

    expect(listener).not.toHaveBeenCalled();
    expect(localStorage.getItem('accessToken')).toBe(validToken);

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

  it('should end the session on a 403 when the stored token has expired', async () => {
    const expiredToken = makeJwt({ sub: 'admin-1', exp: Math.floor(Date.now() / 1000) - 3600 });
    localStorage.setItem('accessToken', expiredToken);
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

  it('should end the session on a 403 when the stored token cannot be decoded', async () => {
    localStorage.setItem('accessToken', 'not-a-jwt');
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

  it('should end the session on a 403 when no token is stored', async () => {
    localStorage.removeItem('accessToken');
    server.use(
      http.get(TEST_URL, () => new HttpResponse(null, { status: 403 }))
    );
    const listener = vi.fn();
    const unsubscribe = authEvents.subscribe(listener);

    await expect(apiClient.get('/pod/dashboard')).rejects.toBeDefined();

    expect(listener).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'session-expired' })
    );
    expect(localStorage.getItem('admin')).toBeNull();

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
