import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import i18n from 'i18next';

import { MembersPage } from './MembersPage';

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
}));

// Mock useAuth
const mockUseAuth = vi.fn();
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => mockUseAuth(),
}));

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: {
          error: 'Error',
          cancel: 'Cancel',
        },
        dashboard: { title: 'Dashboard' },
        members: {
          title: 'Members',
          name: 'Name',
          phone: 'Phone',
          address: 'Address',
          status: 'Status',
          issuesReported: 'Issues Reported',
          joinedAt: 'Joined',
          actions: 'Actions',
          filterByStatus: 'Filter by status',
          filterAll: 'All Members',
          filterPending: 'Pending Approval',
          filterActive: 'Active',
          filterSuspended: 'Suspended',
          approve: 'Approve',
          reject: 'Reject',
          approveTitle: 'Approve Member Registration',
          rejectTitle: 'Reject Member Registration',
          approveConfirmation:
            "Are you sure you want to approve this member's registration?",
          rejectConfirmation:
            "Are you sure you want to reject this member's registration?",
          approveEmailNote:
            'A welcome email with login credentials will be sent to the member.',
          rejectWarning:
            'This will permanently delete the registration.',
          noMembers: 'No Members',
          noMembersDescription: 'No members match your current filters.',
          noPendingMembers: 'No pending registrations to review',
          statuses: {
            active: 'Active',
            pending_approval: 'Pending Approval',
            suspended: 'Suspended',
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
      queries: {
        retry: false,
      },
      mutations: {
        retry: false,
      },
    },
  });
}

interface RenderOptions {
  initialRoute?: string;
}

function renderMembersPage({ initialRoute = '/members' }: RenderOptions = {}) {
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
      sectorId: 'sector-1',
      role: 'SECTOR_ADMIN',
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
              <Route path="/members" element={<MembersPage />} />
              <Route path="/" element={<div data-testid="dashboard">Dashboard</div>} />
            </Routes>
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('MembersPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rendering', () => {
    it('should render the page title', async () => {
      renderMembersPage();

      await waitFor(() => {
        // Should find "Members" somewhere on the page
        expect(screen.getAllByText('Members').length).toBeGreaterThan(0);
      });
    });

    it('should render status filter tabs', async () => {
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByRole('tab', { name: /all members/i })).toBeInTheDocument();
      });
      expect(screen.getByRole('tab', { name: /pending approval/i })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: /^active$/i })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: /suspended/i })).toBeInTheDocument();
    });

    it('should render members table when data is loaded', async () => {
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByText('John Active')).toBeInTheDocument();
        expect(screen.getByText('Jane Pending')).toBeInTheDocument();
        expect(screen.getByText('Bob Suspended')).toBeInTheDocument();
      });
    });

    it('should show pending count badge on pending tab', async () => {
      renderMembersPage();

      await waitFor(() => {
        // The badge should show the count of pending members
        const pendingTab = screen.getByRole('tab', { name: /pending approval/i });
        expect(within(pendingTab).getByText('1')).toBeInTheDocument();
      });
    });
  });

  describe('status filtering', () => {
    it('should filter by pending status when pending tab is clicked', async () => {
      const user = userEvent.setup();
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByRole('tab', { name: /pending approval/i })).toBeInTheDocument();
      });

      await user.click(screen.getByRole('tab', { name: /pending approval/i }));

      await waitFor(() => {
        // Should only show pending members
        expect(screen.getByText('Jane Pending')).toBeInTheDocument();
        expect(screen.queryByText('John Active')).not.toBeInTheDocument();
        expect(screen.queryByText('Bob Suspended')).not.toBeInTheDocument();
      });
    });

    it('should filter by active status when active tab is clicked', async () => {
      const user = userEvent.setup();
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByRole('tab', { name: /^active$/i })).toBeInTheDocument();
      });

      await user.click(screen.getByRole('tab', { name: /^active$/i }));

      await waitFor(() => {
        // Should only show active members
        expect(screen.getByText('John Active')).toBeInTheDocument();
        expect(screen.queryByText('Jane Pending')).not.toBeInTheDocument();
        expect(screen.queryByText('Bob Suspended')).not.toBeInTheDocument();
      });
    });

    it('should filter by suspended status when suspended tab is clicked', async () => {
      const user = userEvent.setup();
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByRole('tab', { name: /suspended/i })).toBeInTheDocument();
      });

      await user.click(screen.getByRole('tab', { name: /suspended/i }));

      await waitFor(() => {
        // Should only show suspended members
        expect(screen.getByText('Bob Suspended')).toBeInTheDocument();
        expect(screen.queryByText('John Active')).not.toBeInTheDocument();
        expect(screen.queryByText('Jane Pending')).not.toBeInTheDocument();
      });
    });

    it('should show all members when all tab is clicked', async () => {
      const user = userEvent.setup();
      renderMembersPage();

      // First filter to pending
      await waitFor(() => {
        expect(screen.getByRole('tab', { name: /pending approval/i })).toBeInTheDocument();
      });
      await user.click(screen.getByRole('tab', { name: /pending approval/i }));

      // Then switch back to all
      await user.click(screen.getByRole('tab', { name: /all members/i }));

      await waitFor(() => {
        expect(screen.getByText('John Active')).toBeInTheDocument();
        expect(screen.getByText('Jane Pending')).toBeInTheDocument();
        expect(screen.getByText('Bob Suspended')).toBeInTheDocument();
      });
    });
  });

  describe('approval actions', () => {
    it('should show approve/reject buttons in all members view', async () => {
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByText('Actions')).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /approve/i })).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /reject/i })).toBeInTheDocument();
      });
    });

    it('should have clickable approve button for pending members', async () => {
      const user = userEvent.setup();
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /approve/i })).toBeInTheDocument();
      });

      // Verify button is clickable (doesn't throw)
      const approveButton = screen.getByRole('button', { name: /approve/i });
      await user.click(approveButton);

      // Dialog component will handle the rest
    });

    it('should have clickable reject button for pending members', async () => {
      const user = userEvent.setup();
      renderMembersPage();

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /reject/i })).toBeInTheDocument();
      });

      // Verify button is clickable (doesn't throw)
      const rejectButton = screen.getByRole('button', { name: /reject/i });
      await user.click(rejectButton);

      // Dialog component will handle the rest
    });
  });

  describe('URL state management', () => {
    it('should use status from URL parameter', async () => {
      renderMembersPage({ initialRoute: '/members?status=pending_approval' });

      await waitFor(() => {
        // Should only show pending members
        expect(screen.getByText('Jane Pending')).toBeInTheDocument();
        expect(screen.queryByText('John Active')).not.toBeInTheDocument();
      });
    });
  });
});
