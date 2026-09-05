import { describe, it, expect, beforeEach } from 'vitest';
import { renderHook } from '@testing-library/react';

import { useAuth } from './useAuth';

describe('useAuth', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('should expose the stored support grant', () => {
    localStorage.setItem('accessToken', 'token');
    localStorage.setItem(
      'admin',
      JSON.stringify({ id: 'grant-1', email: 'support@example.com', displayName: 'Support User', role: 'POD_ADMIN', sectorId: null })
    );
    localStorage.setItem(
      'supportGrant',
      JSON.stringify({ grantId: 'grant-1', grantedRole: 'pod_admin', expiresAt: '2026-09-05T11:00:00Z' })
    );

    const { result } = renderHook(() => useAuth());

    expect(result.current.supportGrant).toEqual({
      grantId: 'grant-1',
      grantedRole: 'pod_admin',
      expiresAt: '2026-09-05T11:00:00Z',
    });
  });

  it('should limit permissions to the granted role under a support grant', () => {
    localStorage.setItem('accessToken', 'token');
    localStorage.setItem(
      'admin',
      JSON.stringify({ id: 'grant-1', email: 'support@example.com', displayName: 'Support User', role: 'POD_ADMIN', sectorId: null })
    );
    localStorage.setItem(
      'supportGrant',
      JSON.stringify({ grantId: 'grant-1', grantedRole: 'pod_admin', expiresAt: '2026-09-05T11:00:00Z' })
    );

    const { result } = renderHook(() => useAuth());

    expect(result.current.hasPermission('pod_chief')).toBe(false);
    expect(result.current.hasPermission('ward_admin')).toBe(true);
  });

  it('should clear the support grant on logout', () => {
    localStorage.setItem('accessToken', 'token');
    localStorage.setItem(
      'supportGrant',
      JSON.stringify({ grantId: 'grant-1', grantedRole: 'pod_admin', expiresAt: '2026-09-05T11:00:00Z' })
    );

    const { result } = renderHook(() => useAuth());

    result.current.logout();

    expect(localStorage.getItem('supportGrant')).toBeNull();
  });
});
