import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';

import { server } from '@/test/mocks/server';
import { DashboardPage } from './DashboardPage';
import type { SetupStep, PodSetupState } from '@/shared/hooks/usePodSetup';

const POD_DASHBOARD_URL = '*/pod/dashboard';

// Mock the hooks
const mockPodSetup: PodSetupState = {
  status: null,
  isSetupComplete: true,
  showAreaDashboards: false,
  showPodAdmins: false,
  isPodLevel: false,
  isLoading: false,
};

vi.mock('@/shared/hooks/usePodSetup', () => ({
  usePodSetup: () => mockPodSetup,
}));

vi.mock('./hooks', () => ({
  useDashboardStats: () => ({
    data: {
      stats: {
        totalOpen: 10,
        reportedThisWeek: 5,
        avgResolutionDays: 3,
        byState: { reported: 3, confirmed: 2, in_progress: 3, fixed: 2 },
        byType: { pothole: 4, water_leak: 3, street_light: 3 },
      },
    },
    isLoading: false,
    error: null,
    refetch: vi.fn(),
  }),
}));

// hasPermission is mutable per test so we can simulate a pod admin
// (no pod_chief permission) versus a pod chief.
let mockHasPermission: (role: string) => boolean = () => true;

vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => ({
    hasPermission: (role: string) => mockHasPermission(role),
  }),
}));

// The pod dashboard hook and API are real here (not mocked): the point of
// these tests is to prove GET /pod/dashboard is only ever requested for a
// user with the pod_chief permission (#114).

// Mock react-i18next
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const translations: Record<string, string> = {
        'common.configure': 'Configure',
        'podChief.setup.podName': 'Set Pod Name',
        'podChief.setup.podNameDescription': 'Configure your pod display name.',
        'podChief.setup.firstAdmin': 'Add First Administrator',
        'podChief.setup.firstAdminDescription': 'Invite your first admin.',
      };
      return translations[key] ?? key;
    },
  }),
}));

// Mock the DashboardLayout to simplify testing
vi.mock('@/components/templates/DashboardLayout', () => ({
  DashboardLayout: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="dashboard-layout">{children}</div>
  ),
}));

// Mock child components
vi.mock('./components/StatsGrid', () => ({
  StatsGrid: () => <div data-testid="stats-grid">Stats Grid</div>,
}));

vi.mock('./components/IssuesByStateChart', () => ({
  IssuesByStateChart: () => (
    <div data-testid="issues-by-state-chart">Issues by State</div>
  ),
}));

vi.mock('./components/IssuesByTypeChart', () => ({
  IssuesByTypeChart: () => (
    <div data-testid="issues-by-type-chart">Issues by Type</div>
  ),
}));

vi.mock('@/features/pod-chief/components', () => ({
  SetupBanners: ({ missingSteps }: { missingSteps: string[] }) => (
    <div data-testid="setup-banners">
      {missingSteps.map((step) => (
        <div key={step}>{step === 'pod_name' ? 'Set Pod Name' : step === 'first_admin' ? 'Add First Administrator' : step}</div>
      ))}
    </div>
  ),
  PodChiefWidgets: () => <div data-testid="pod-chief-widgets">Pod Chief Widgets</div>,
}));

const renderWithProviders = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>{ui}</MemoryRouter>
    </QueryClientProvider>
  );
};

describe('DashboardPage', () => {
  beforeEach(() => {
    // Reset mock to default state
    mockPodSetup.status = null;
    mockPodSetup.isSetupComplete = true;
    mockPodSetup.showAreaDashboards = false;
    mockPodSetup.showPodAdmins = false;
    mockPodSetup.isPodLevel = false;
    mockPodSetup.isLoading = false;
    mockHasPermission = () => true;
  });

  it('renders dashboard content for non-pod-level users', () => {
    renderWithProviders(<DashboardPage />);

    expect(screen.getByTestId('stats-grid')).toBeInTheDocument();
    expect(screen.getByTestId('issues-by-state-chart')).toBeInTheDocument();
    expect(screen.getByTestId('issues-by-type-chart')).toBeInTheDocument();
  });

  it('does not show setup banners for non-pod-level users', () => {
    mockPodSetup.isPodLevel = false;
    mockPodSetup.isSetupComplete = false;
    mockPodSetup.status = {
      isComplete: false,
      missingSteps: ['pod_name'] as SetupStep[],
      wards: [],
      sectors: [],
    };

    renderWithProviders(<DashboardPage />);

    expect(screen.queryByText('Set Pod Name')).not.toBeInTheDocument();
  });

  it('shows setup banners for pod-level users with incomplete setup', () => {
    mockPodSetup.isPodLevel = true;
    mockPodSetup.isSetupComplete = false;
    mockPodSetup.status = {
      isComplete: false,
      missingSteps: ['pod_name', 'first_admin'] as SetupStep[],
      wards: [],
      sectors: [],
    };

    renderWithProviders(<DashboardPage />);

    expect(screen.getByText('Set Pod Name')).toBeInTheDocument();
    expect(screen.getByText('Add First Administrator')).toBeInTheDocument();
  });

  it('shows pod chief widgets when pod setup is complete', async () => {
    mockPodSetup.isPodLevel = true;
    mockPodSetup.isSetupComplete = true;
    mockPodSetup.status = {
      isComplete: true,
      missingSteps: [],
      wards: [{ id: 'w1', name: 'Ward 1' }],
      sectors: [],
    };

    server.use(
      http.get(POD_DASHBOARD_URL, () =>
        HttpResponse.json({
          totalIssues: 150,
          openIssues: 45,
          resolvedThisMonth: 23,
          pendingIssues: 12,
          activeAdministrators: 5,
          totalMembers: 1250,
          activeGroundAdmins: 8,
          wardCount: 4,
          sectorCount: 16,
        })
      )
    );

    renderWithProviders(<DashboardPage />);

    // Should show pod chief widgets, not sector dashboard
    await waitFor(() => expect(screen.getByTestId('pod-chief-widgets')).toBeInTheDocument());
    expect(screen.queryByTestId('stats-grid')).not.toBeInTheDocument();
    expect(screen.queryByText('Set Pod Name')).not.toBeInTheDocument();
  });

  it('shows setup banners but no widgets when pod setup is incomplete', () => {
    mockPodSetup.isPodLevel = true;
    mockPodSetup.isSetupComplete = false;
    mockPodSetup.status = {
      isComplete: false,
      missingSteps: ['pod_name'] as SetupStep[],
      wards: [],
      sectors: [],
    };

    renderWithProviders(<DashboardPage />);

    // Should show setup banners but no dashboard widgets
    expect(screen.getByTestId('setup-banners')).toBeInTheDocument();
    expect(screen.getByText('Set Pod Name')).toBeInTheDocument();
    expect(screen.queryByTestId('pod-chief-widgets')).not.toBeInTheDocument();
    expect(screen.queryByTestId('stats-grid')).not.toBeInTheDocument();
  });

  it('should not request the pod dashboard for a pod admin', async () => {
    // A pod admin: pod-level and setup complete, but lacking pod_chief
    // permission. GET /pod/dashboard must never be requested (#114).
    mockPodSetup.isPodLevel = true;
    mockPodSetup.isSetupComplete = true;
    mockPodSetup.status = {
      isComplete: true,
      missingSteps: [],
      wards: [],
      sectors: [],
    };
    mockHasPermission = (role: string) => role !== 'pod_chief';

    let requestCount = 0;
    server.use(
      http.get(POD_DASHBOARD_URL, () => {
        requestCount += 1;
        return HttpResponse.json({});
      })
    );

    renderWithProviders(<DashboardPage />);

    // Wait for the page to settle, then confirm the disabled query never
    // fired: with `enabled: false` there is no async gap to race, so this
    // resolves immediately rather than depending on a fixed sleep.
    await waitFor(() => {
      expect(screen.getByTestId('dashboard-layout')).toBeInTheDocument();
    });

    expect(requestCount).toBe(0);
  });
});
