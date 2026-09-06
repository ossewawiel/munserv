import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import i18n from 'i18next';

import { ReportsPage } from './ReportsPage';

// Mock useThemeContext - need to mock both locations it's imported from
const mockUseThemeContext = vi.fn();
vi.mock('@/theme', async () => {
  const actual = await vi.importActual('@/theme');
  return {
    ...actual,
    useThemeContext: () => mockUseThemeContext(),
  };
});

vi.mock('@/theme/ThemeContext', async () => {
  const actual = await vi.importActual('@/theme/ThemeContext');
  return {
    ...actual,
    useThemeContext: () => mockUseThemeContext(),
  };
});

// Mock useLogout
vi.mock('@/features/auth/hooks', () => ({
  useLogout: () => ({
    mutate: vi.fn(),
    isPending: false,
  }),
  useCurrentSupportGrant: () => ({
    data: undefined,
  }),
}));

// Mock useAuth
const mockUseAuth = vi.fn();
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => mockUseAuth(),
}));

// Mock usePodSetup
vi.mock('@/shared/hooks/usePodSetup', () => ({
  usePodSetup: () => ({
    status: {
      isComplete: true,
      missingSteps: [],
      wards: [{ id: 'ward-1', name: 'Ward North' }],
      sectors: [{ id: 'sector-1', name: 'Sector A' }],
    },
    isSetupComplete: true,
    showAreaDashboards: true,
    showPodAdmins: true,
    isPodLevel: true,
    isLoading: false,
  }),
}));

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: { appName: 'MunServ Admin', error: 'Error', cancel: 'Cancel' },
        dashboard: { title: 'Dashboard' },
        reports: {
          title: 'Reports',
          tabsLabel: 'Report sections',
          scopes: {
            pod: 'Pod reports',
            ward: 'Ward reports',
            sector: 'Sector reports',
          },
          tabs: {
            summary: 'Summary',
            issues: 'Issues',
            performance: 'Performance',
          },
          empty: {
            title: 'No report data yet',
            description: 'Once members log issues in this scope, the summary, issue breakdown and performance figures appear here.',
          },
        },
        errors: { serverError: 'Server Error' },
        pagination: {
          page: 'Page',
          of: 'of',
          showing: 'Showing',
          to: 'to',
          results: 'results',
          rowsPerPage: 'Rows per page',
        },
      },
    },
  },
});

const theme = createTheme();

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

interface RenderOptions {
  initialRoute?: string;
}

function renderReportsPage({ initialRoute = '/reports/general' }: RenderOptions = {}) {
  const queryClient = createTestQueryClient();

  mockUseThemeContext.mockReturnValue({
    colorMode: 'light',
    setColorMode: vi.fn(),
    podConfig: { podId: 'test', fonts: { primary: 'Roboto' }, colors: {} },
    isLoading: false,
  });

  mockUseAuth.mockReturnValue({
    isAuthenticated: true,
    admin: {
      id: 'admin-1',
      email: 'chief@ward42.example.com',
      displayName: 'Test Chief',
      sectorId: 'sector-1',
      role: 'pod_chief',
    },
    login: vi.fn(),
    logout: vi.fn(),
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter initialEntries={[initialRoute]}>
            <Routes>
              <Route path="/reports/general" element={<ReportsPage scope="pod" />} />
              <Route path="/reports/ward/:wardId" element={<ReportsPage scope="ward" />} />
              <Route path="/reports/sector/:sectorId" element={<ReportsPage scope="sector" />} />
              <Route path="/" element={<div data-testid="dashboard">Dashboard</div>} />
            </Routes>
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('ReportsPage', () => {
  it('should render the three report tabs', () => {
    renderReportsPage();

    expect(screen.getByRole('tab', { name: 'Summary' })).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: 'Issues' })).toBeInTheDocument();
    expect(screen.getByRole('tab', { name: 'Performance' })).toBeInTheDocument();
  });

  it('should show the ward name in the breadcrumb for a ward report', () => {
    renderReportsPage({ initialRoute: '/reports/ward/ward-1' });

    expect(screen.getAllByText('Ward North').length).toBeGreaterThan(0);
  });

  it('should put the selected tab in the query string', () => {
    renderReportsPage({ initialRoute: '/reports/general?tab=issues' });

    const issuesTab = screen.getByRole('tab', { name: 'Issues' });
    expect(issuesTab).toHaveAttribute('aria-selected', 'true');
  });

  it('should fall back to the summary tab for an unknown tab value', () => {
    renderReportsPage({ initialRoute: '/reports/general?tab=bogus' });

    const summaryTab = screen.getByRole('tab', { name: 'Summary' });
    expect(summaryTab).toHaveAttribute('aria-selected', 'true');
  });
});
