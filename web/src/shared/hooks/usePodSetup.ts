import { useMemo } from 'react';

import { useAuth } from '@/shared/hooks/useAuth';
import { hasPermission } from '@/shared/types/admin';

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
 * TODO: Connect to actual backend endpoint when available (GET /api/v1/pod/status).
 */
export function usePodSetup(): PodSetupState {
  const { admin } = useAuth();
  const isPodLevel = Boolean(admin && hasPermission(admin.role, 'pod_admin'));

  // For MVP, use static mock data
  // TODO: Replace with React Query hook when backend endpoint is available
  const mockStatus: PodSetupStatus = useMemo(
    () => ({
      isComplete: true,
      missingSteps: [],
      wards: [
        { id: 'ward-1', name: 'Ward 1' },
        { id: 'ward-2', name: 'Ward 2' },
      ],
      sectors: [
        { id: 'sector-1', name: 'Sector A' },
        { id: 'sector-2', name: 'Sector B' },
        { id: 'sector-3', name: 'Sector C' },
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
