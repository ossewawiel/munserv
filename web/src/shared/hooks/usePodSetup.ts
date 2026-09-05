import { useMemo } from 'react';

import { useAuth } from '@/shared/hooks/useAuth';
import { hasPermission, isAdminRole, SUPER_USER_ROLE } from '@/shared/types/admin';

/**
 * Setup step identifiers for tracking incomplete configuration
 */
export type SetupStep = 'pod_name' | 'pod_boundaries' | 'wards_sectors' | 'first_admin';

/**
 * Pod setup status
 */
export interface PodSetupStatus {
  /** Whether all required setup steps are complete */
  isComplete: boolean;
  /** List of missing setup steps */
  missingSteps: SetupStep[];
  /** List of configured wards (for navigation submenu) */
  wards: Array<{ id: string; name: string }>;
  /** List of configured sectors (for navigation submenu) */
  sectors: Array<{ id: string; name: string }>;
}

/**
 * Derived setup state for UI consumption
 */
export interface PodSetupState {
  /** Raw setup status */
  status: PodSetupStatus | null;
  /** Whether the pod setup is complete enough to show full navigation */
  isSetupComplete: boolean;
  /** Whether to show ward/sector dashboard submenus */
  showAreaDashboards: boolean;
  /** Whether to show pod administrators menu */
  showPodAdmins: boolean;
  /** Whether the current user is a pod-level admin */
  isPodLevel: boolean;
  /** Loading state */
  isLoading: boolean;
}

/**
 * Hook to get pod setup status for navigation and UI decisions.
 * Only returns data for users with pod_admin or higher permissions.
 *
 * For MVP: Returns mock data indicating setup is complete.
 * Tracked in #59: wire to GET /api/v1/pod/status once it returns wards and sectors.
 */
export function usePodSetup(): PodSetupState {
  const { admin } = useAuth();
  // Super users and pod-level admins can see pod setup
  const isPodLevel = Boolean(
    admin &&
      (admin.role === SUPER_USER_ROLE ||
        (isAdminRole(admin.role) && hasPermission(admin.role, 'pod_admin')))
  );

  // For MVP, use static mock data with real UUIDs from database
  // Tracked in #59: replace with a React Query hook
  const mockStatus: PodSetupStatus = useMemo(
    () => ({
      isComplete: true,
      missingSteps: [],
      wards: [
        { id: '550e8400-e29b-41d4-a716-446655440030', name: 'Test Ward North' },
      ],
      sectors: [
        { id: '550e8400-e29b-41d4-a716-446655440001', name: 'Ward 42 - Northcliff' },
        { id: '550e8400-e29b-41d4-a716-446655440002', name: 'Ward 43 - Fairlands' },
      ],
    }),
    []
  );

  const state = useMemo<PodSetupState>(() => {
    if (!isPodLevel) {
      return {
        status: null,
        isSetupComplete: false,
        showAreaDashboards: false,
        showPodAdmins: false,
        isPodLevel: false,
        isLoading: false,
      };
    }

    const status = mockStatus;

    // Show area dashboards when areas are configured
    const showAreaDashboards = status.wards.length > 0 || status.sectors.length > 0;

    // Show pod admins when setup is complete (pod chief can manage admins)
    const showPodAdmins = status.isComplete;

    return {
      status,
      isSetupComplete: status.isComplete,
      showAreaDashboards,
      showPodAdmins,
      isPodLevel: true,
      isLoading: false,
    };
  }, [isPodLevel, mockStatus]);

  return state;
}
