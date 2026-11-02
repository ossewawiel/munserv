import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, within, fireEvent, act } from '@testing-library/react';
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
const mockUsePodAdministrators = vi.fn();
vi.mock('./hooks', () => ({
  usePodAdministrators: (query: unknown) => mockUsePodAdministrators(query),
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
          emptyFiltered: 'No administrators match your search or filters.',
          filters: { role: 'Role', assignedTo: 'Assigned to', allAssignments: 'All assignments' },
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

function renderPage(entry = '/pod-administrators') {
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
    hasPermission: () => true,
    supportGrant: null,
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter initialEntries={[entry]}>
            <PodAdministratorsPage />
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('PodAdministratorsPage', () => {
  const lastQuery = (): unknown => mockUsePodAdministrators.mock.calls.at(-1)?.[0];

  beforeEach(() => {
    vi.clearAllMocks();
    mockUsePodAdministrators.mockReturnValue({
      data: { items: admins, total: admins.length },
      isLoading: false,
      error: null,
    });
  });

  it('should read the sort search and filters from the url', () => {
    renderPage(
      '/pod-administrators?q=khumalo&role=ward_chief&role=ward_admin&ward=ward-1&sort=displayName:desc'
    );

    expect(lastQuery()).toEqual({
      q: 'khumalo',
      roles: ['ward_chief', 'ward_admin'],
      wardId: 'ward-1',
      sort: { column: 'displayName', direction: 'desc' },
    });
  });

  it('should ignore an unknown sort column in the url', () => {
    renderPage('/pod-administrators?sort=assignedTo:asc');

    expect(lastQuery()).toMatchObject({ sort: undefined });
  });

  it('should toggle the direction when the same header is clicked twice', () => {
    renderPage();
    const sortButton = () =>
      within(screen.getByRole('columnheader', { name: 'Name' })).getByRole('button');

    fireEvent.click(sortButton());
    expect(lastQuery()).toMatchObject({ sort: { column: 'displayName', direction: 'asc' } });

    fireEvent.click(sortButton());
    expect(lastQuery()).toMatchObject({ sort: { column: 'displayName', direction: 'desc' } });
  });

  it('should not make assigned to sortable', () => {
    renderPage();

    const header = screen.getByRole('columnheader', { name: 'Assigned To' });
    expect(within(header).queryByRole('button')).not.toBeInTheDocument();
  });

  describe('search debounce', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should send the search term after the debounce', () => {
      renderPage();

      fireEvent.change(screen.getByRole('textbox', { name: 'Search' }), {
        target: { value: 'ward' },
      });
      act(() => {
        vi.advanceTimersByTime(300);
      });

      expect(lastQuery()).toMatchObject({ q: 'ward' });
    });

    it('should not send the search term before the debounce', () => {
      renderPage();

      fireEvent.change(screen.getByRole('textbox', { name: 'Search' }), {
        target: { value: 'ward' },
      });
      act(() => {
        vi.advanceTimersByTime(299);
      });

      expect(lastQuery()).not.toMatchObject({ q: 'ward' });
      expect(screen.getByRole('textbox', { name: 'Search' })).toHaveValue('ward');
    });
  });

  it('should badge the filter button with the number of active filters', () => {
    renderPage('/pod-administrators?role=ward_chief&role=ward_admin&ward=ward-1');

    const button = screen.getByRole('button', { name: 'Filters' });
    expect(within(button.parentElement as HTMLElement).getByText('3')).toBeInTheDocument();
  });

  it('should show the filtered empty message when a search matches nothing', () => {
    mockUsePodAdministrators.mockReturnValue({
      data: { items: [], total: 0 },
      isLoading: false,
      error: null,
    });
    renderPage('/pod-administrators?q=zzzz');

    expect(screen.getByText('No administrators match your search or filters.')).toBeInTheDocument();
  });
});
