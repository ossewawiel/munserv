import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import i18n from 'i18next';

import { PodAdministratorsPage } from './PodAdministratorsPage';
import type { PodAdministrator } from './types';

// Mock useThemeContext - needed by DashboardLayout
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

// Mock auth hooks used by DashboardLayout chrome
vi.mock('@/features/auth/hooks', () => ({
  useLogout: () => ({ mutate: vi.fn(), isPending: false }),
  useCurrentSupportGrant: () => ({ data: undefined }),
}));

const mockUseAuth = vi.fn();
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => mockUseAuth(),
}));

const admins: PodAdministrator[] = [
  {
    id: 'admin-1',
    email: 'thabo.mokoena@ward42.example.com',
    displayName: 'Thabo Mokoena',
    role: 'pod_chief',
    level: 'pod',
    podId: 'pod-1',
    wardId: null,
    sectorId: null,
    createdAt: '2026-01-12T00:00:00Z',
    deletedAt: null,
  },
];

// Mock this feature's own data hooks - the table's data source is not under test here
vi.mock('./hooks', () => ({
  usePodAdministrators: () => ({
    data: { items: admins, total: admins.length },
    isLoading: false,
    error: null,
  }),
  useCreatePodAdministrator: () => ({ mutate: vi.fn(), isPending: false, reset: vi.fn() }),
  useUpdatePodAdministrator: () => ({ mutate: vi.fn(), isPending: false }),
  useDeletePodAdministrator: () => ({ mutate: vi.fn(), isPending: false }),
}));

i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: {
          edit: 'Edit',
          delete: 'Delete',
          notAvailable: 'N/A',
        },
        dashboard: { title: 'Dashboard' },
        podAdministrators: {
          title: 'Pod Administrators',
          subtitle: 'Manage administrators across all levels of your pod',
          addNew: 'Add Administrator',
          empty: 'No administrators found.',
          filters: {
            comingSoon: 'Filtering is not switched on yet.',
          },
          table: {
            name: 'Name',
            email: 'Email',
            role: 'Role',
            assignedTo: 'Assigned To',
            createdAt: 'Created',
            actions: 'Actions',
            podLevel: 'Pod Level',
            wardAssigned: 'Ward Assigned',
            sectorAssigned: 'Sector Assigned',
          },
        },
        dataTable: {
          searchPlaceholder: 'Search',
          filters: 'Filters',
          filtersTitle: 'Filters',
          clearFilters: 'Clear filters',
          closeFilters: 'Close filters',
          sortBy: 'Sort by',
        },
        pagination: {
          page: 'Page',
          of: 'of',
          showing: 'Showing',
          to: 'to',
          results: 'results',
          rowsPerPage: 'Rows per page',
        },
        errors: { loadFailed: 'Failed to load administrators' },
      },
    },
  },
});

const theme = createTheme();

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
}

function renderPage() {
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
      email: 'admin@ward42.example.com',
      displayName: 'Test Admin',
      role: 'pod_chief',
    },
    login: vi.fn(),
    logout: vi.fn(),
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter initialEntries={['/pod-administrators']}>
            <PodAdministratorsPage />
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('PodAdministratorsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should show a disabled search field', () => {
    renderPage();

    expect(screen.getByPlaceholderText('Search')).toBeDisabled();
  });

  it('should show a disabled filter button', () => {
    renderPage();

    expect(screen.getByRole('button', { name: 'Filters' })).toBeInTheDocument();
  });

  it('should show sortable headers that do nothing', () => {
    renderPage();

    const nameHeader = screen.getByRole('columnheader', { name: 'Name' });
    const sortButton = within(nameHeader).getByRole('button');

    expect(sortButton).toHaveAttribute('aria-disabled', 'true');

    const actionsHeader = screen.getByRole('columnheader', { name: 'Actions' });
    expect(within(actionsHeader).queryByRole('button')).not.toBeInTheDocument();
  });
});
