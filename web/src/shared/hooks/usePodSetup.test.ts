import { renderHook } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { usePodSetup } from './usePodSetup';

// Mock useAuth
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: vi.fn(),
}));

import { useAuth } from '@/shared/hooks/useAuth';

const mockUseAuth = vi.mocked(useAuth);

describe('usePodSetup', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('when user is not at pod level', () => {
    it('should return empty state for sector_admin', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: null,
        admin: { id: '1', email: 'test@test.com', displayName: 'Test', sectorId: 's1', role: 'sector_admin' },
        isAuthenticated: true,
        login: vi.fn(),
        logout: vi.fn(),
        hasPermission: vi.fn(),
      });

      const { result } = renderHook(() => usePodSetup());

      expect(result.current.isPodLevel).toBe(false);
      expect(result.current.status).toBeNull();
      expect(result.current.isSetupComplete).toBe(false);
      expect(result.current.showAreaDashboards).toBe(false);
      expect(result.current.showPodAdmins).toBe(false);
    });

    it('should return empty state for sector_chief', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: null,
        admin: { id: '1', email: 'test@test.com', displayName: 'Test', sectorId: 's1', role: 'sector_chief' },
        isAuthenticated: true,
        login: vi.fn(),
        logout: vi.fn(),
        hasPermission: vi.fn(),
      });

      const { result } = renderHook(() => usePodSetup());

      expect(result.current.isPodLevel).toBe(false);
      expect(result.current.status).toBeNull();
    });

    it('should return empty state for ward_chief', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: null,
        admin: { id: '1', email: 'test@test.com', displayName: 'Test', sectorId: 's1', role: 'ward_chief' },
        isAuthenticated: true,
        login: vi.fn(),
        logout: vi.fn(),
        hasPermission: vi.fn(),
      });

      const { result } = renderHook(() => usePodSetup());

      expect(result.current.isPodLevel).toBe(false);
    });
  });

  describe('when user is at pod level', () => {
    it('should return full state for pod_admin', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: null,
        admin: { id: '1', email: 'test@test.com', displayName: 'Test', sectorId: 's1', role: 'pod_admin' },
        isAuthenticated: true,
        login: vi.fn(),
        logout: vi.fn(),
        hasPermission: vi.fn(),
      });

      const { result } = renderHook(() => usePodSetup());

      expect(result.current.isPodLevel).toBe(true);
      expect(result.current.status).not.toBeNull();
      expect(result.current.isSetupComplete).toBe(true);
      expect(result.current.showAreaDashboards).toBe(true);
      expect(result.current.showPodAdmins).toBe(true);
    });

    it('should return full state for pod_chief', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: null,
        admin: { id: '1', email: 'test@test.com', displayName: 'Test', sectorId: 's1', role: 'pod_chief' },
        isAuthenticated: true,
        login: vi.fn(),
        logout: vi.fn(),
        hasPermission: vi.fn(),
      });

      const { result } = renderHook(() => usePodSetup());

      expect(result.current.isPodLevel).toBe(true);
      expect(result.current.status).not.toBeNull();
      expect(result.current.isSetupComplete).toBe(true);
    });

    it('should return mock wards and sectors for navigation', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: null,
        admin: { id: '1', email: 'test@test.com', displayName: 'Test', sectorId: 's1', role: 'pod_chief' },
        isAuthenticated: true,
        login: vi.fn(),
        logout: vi.fn(),
        hasPermission: vi.fn(),
      });

      const { result } = renderHook(() => usePodSetup());

      expect(result.current.status?.wards).toBeDefined();
      expect(result.current.status?.wards.length).toBeGreaterThan(0);
      expect(result.current.status?.sectors).toBeDefined();
      expect(result.current.status?.sectors.length).toBeGreaterThan(0);
    });
  });

  describe('when user is not authenticated', () => {
    it('should return empty state', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: null,
        admin: null,
        isAuthenticated: false,
        login: vi.fn(),
        logout: vi.fn(),
        hasPermission: vi.fn(),
      });

      const { result } = renderHook(() => usePodSetup());

      expect(result.current.isPodLevel).toBe(false);
      expect(result.current.status).toBeNull();
    });
  });
});
