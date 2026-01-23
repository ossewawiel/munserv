import { describe, it, expect } from 'vitest';
import {
  hasPermission,
  canManageRole,
  normalizeRole,
  ADMIN_ROLES,
  type AdminRole,
} from './admin';

describe('admin role utilities', () => {
  describe('hasPermission', () => {
    it('should return true when user role equals required role', () => {
      expect(hasPermission('sector_admin', 'sector_admin')).toBe(true);
      expect(hasPermission('sector_chief', 'sector_chief')).toBe(true);
      expect(hasPermission('ward_admin', 'ward_admin')).toBe(true);
      expect(hasPermission('ward_chief', 'ward_chief')).toBe(true);
      expect(hasPermission('pod_admin', 'pod_admin')).toBe(true);
      expect(hasPermission('pod_chief', 'pod_chief')).toBe(true);
    });

    it('should return true when user role is higher than required', () => {
      expect(hasPermission('sector_chief', 'sector_admin')).toBe(true);
      expect(hasPermission('ward_admin', 'sector_chief')).toBe(true);
      expect(hasPermission('ward_chief', 'ward_admin')).toBe(true);
      expect(hasPermission('pod_admin', 'ward_chief')).toBe(true);
      expect(hasPermission('pod_chief', 'pod_admin')).toBe(true);
      expect(hasPermission('pod_chief', 'sector_admin')).toBe(true);
    });

    it('should return false when user role is lower than required', () => {
      expect(hasPermission('sector_admin', 'sector_chief')).toBe(false);
      expect(hasPermission('sector_admin', 'pod_admin')).toBe(false);
      expect(hasPermission('sector_chief', 'ward_admin')).toBe(false);
      expect(hasPermission('ward_admin', 'ward_chief')).toBe(false);
      expect(hasPermission('ward_chief', 'pod_admin')).toBe(false);
      expect(hasPermission('pod_admin', 'pod_chief')).toBe(false);
    });

    it('should follow correct hierarchy order', () => {
      const roles: AdminRole[] = [
        'sector_admin',
        'sector_chief',
        'ward_admin',
        'ward_chief',
        'pod_admin',
        'pod_chief',
      ];

      for (let i = 0; i < roles.length; i++) {
        // Each role should have permission for itself and all lower roles
        for (let j = 0; j <= i; j++) {
          expect(hasPermission(roles[i], roles[j])).toBe(true);
        }
        // Each role should NOT have permission for higher roles
        for (let j = i + 1; j < roles.length; j++) {
          expect(hasPermission(roles[i], roles[j])).toBe(false);
        }
      }
    });
  });

  describe('canManageRole', () => {
    it('should return true when user can manage a lower role', () => {
      expect(canManageRole('sector_chief', 'sector_admin')).toBe(true);
      expect(canManageRole('ward_admin', 'sector_chief')).toBe(true);
      expect(canManageRole('ward_chief', 'ward_admin')).toBe(true);
      expect(canManageRole('pod_admin', 'ward_chief')).toBe(true);
      expect(canManageRole('pod_admin', 'sector_admin')).toBe(true);
      expect(canManageRole('pod_chief', 'pod_admin')).toBe(true);
    });

    it('should return false when trying to manage same role', () => {
      expect(canManageRole('sector_admin', 'sector_admin')).toBe(false);
      expect(canManageRole('sector_chief', 'sector_chief')).toBe(false);
      expect(canManageRole('ward_admin', 'ward_admin')).toBe(false);
      expect(canManageRole('ward_chief', 'ward_chief')).toBe(false);
      expect(canManageRole('pod_admin', 'pod_admin')).toBe(false);
      expect(canManageRole('pod_chief', 'pod_chief')).toBe(false);
    });

    it('should return false when trying to manage higher role', () => {
      expect(canManageRole('sector_admin', 'sector_chief')).toBe(false);
      expect(canManageRole('sector_chief', 'ward_admin')).toBe(false);
      expect(canManageRole('ward_admin', 'ward_chief')).toBe(false);
      expect(canManageRole('ward_chief', 'pod_admin')).toBe(false);
      expect(canManageRole('pod_admin', 'pod_chief')).toBe(false);
    });
  });

  describe('normalizeRole', () => {
    it('should normalize lowercase roles', () => {
      expect(normalizeRole('sector_admin')).toBe('sector_admin');
      expect(normalizeRole('sector_chief')).toBe('sector_chief');
      expect(normalizeRole('ward_admin')).toBe('ward_admin');
      expect(normalizeRole('ward_chief')).toBe('ward_chief');
      expect(normalizeRole('pod_admin')).toBe('pod_admin');
      expect(normalizeRole('pod_chief')).toBe('pod_chief');
    });

    it('should normalize uppercase roles (backend format)', () => {
      expect(normalizeRole('SECTOR_ADMIN')).toBe('sector_admin');
      expect(normalizeRole('SECTOR_CHIEF')).toBe('sector_chief');
      expect(normalizeRole('WARD_ADMIN')).toBe('ward_admin');
      expect(normalizeRole('WARD_CHIEF')).toBe('ward_chief');
      expect(normalizeRole('POD_ADMIN')).toBe('pod_admin');
      expect(normalizeRole('POD_CHIEF')).toBe('pod_chief');
    });

    it('should handle mixed case roles', () => {
      expect(normalizeRole('Sector_Admin')).toBe('sector_admin');
      expect(normalizeRole('SECTOR_chief')).toBe('sector_chief');
      expect(normalizeRole('Ward_Admin')).toBe('ward_admin');
    });

    it('should default to sector_admin for unknown roles', () => {
      expect(normalizeRole('unknown_role')).toBe('sector_admin');
      expect(normalizeRole('')).toBe('sector_admin');
    });
  });

  describe('ADMIN_ROLES constant', () => {
    it('should contain all roles in correct order', () => {
      expect(ADMIN_ROLES).toEqual([
        'sector_admin',
        'sector_chief',
        'ward_admin',
        'ward_chief',
        'pod_admin',
        'pod_chief',
      ]);
    });

    it('should have 6 roles', () => {
      expect(ADMIN_ROLES).toHaveLength(6);
    });
  });
});
