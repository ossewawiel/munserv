import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { Sidebar } from './Sidebar';

// Mock useAuth
const mockAdmin = { role: 'pod_chief' as const, displayName: 'Test User' };
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => ({ admin: mockAdmin, isAuthenticated: true }),
}));

// Mock usePodSetup
vi.mock('@/shared/hooks/usePodSetup', () => ({
  usePodSetup: () => ({
    status: {
      isComplete: true,
      missingSteps: [],
      wards: [
        { id: 'ward-1', name: 'Ward North' },
        { id: 'ward-2', name: 'Ward South' },
      ],
      sectors: [
        { id: 'sector-1', name: 'Sector A' },
        { id: 'sector-2', name: 'Sector B' },
      ],
    },
    isSetupComplete: true,
    showAreaDashboards: true,
    showPodAdmins: true,
    isPodLevel: true,
    isLoading: false,
  }),
}));

// Mock useUnreadCount
vi.mock('@/features/messages/hooks', () => ({
  useUnreadCount: () => ({ data: 0 }),
}));

// Mock admin types
vi.mock('@/shared/types/admin', () => ({
  SUPER_USER_ROLE: 'SUPER_USER',
  isAdminRole: (role: string) => role !== 'SUPER_USER',
  hasPermission: (role: string, required: string) => {
    const hierarchy = ['sector_admin', 'sector_chief', 'ward_admin', 'ward_chief', 'pod_admin', 'pod_chief'];
    return hierarchy.indexOf(role) >= hierarchy.indexOf(required);
  },
}));

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: { appName: 'MunServ Admin' },
        nav: {
          dashboard: 'Dashboard',
          wardDashboards: 'Ward Dashboards',
          sectorDashboards: 'Sector Dashboards',
          podAdministrators: 'Pod Administrators',
          reports: 'Reports',
          generalReports: 'General',
          messages: 'Messages',
          podSettings: 'Pod Settings',
        },
      },
    },
  },
});

const theme = createTheme({
  palette: { mode: 'light' },
});

interface RenderOptions {
  initialPath?: string;
}

function renderSidebar({ initialPath = '/' }: RenderOptions = {}) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter initialEntries={[initialPath]}>
            <Sidebar open={true} onClose={vi.fn()} variant="permanent" />
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('Sidebar', () => {
  describe('submenu behavior', () => {
    it('should expand submenu when clicking on parent item', () => {
      renderSidebar();

      // Ward Dashboards should be visible but collapsed
      const wardDashboardsButton = screen.getByRole('button', { name: /ward dashboards/i });
      expect(wardDashboardsButton).toBeInTheDocument();

      // Children should not be visible initially
      expect(screen.queryByText('Ward North')).not.toBeInTheDocument();

      // Click to expand
      fireEvent.click(wardDashboardsButton);

      // Children should now be visible
      expect(screen.getByText('Ward North')).toBeInTheDocument();
      expect(screen.getByText('Ward South')).toBeInTheDocument();
    });

    it('should keep submenu expanded when navigating to a child page', () => {
      // Start on a ward dashboard page
      renderSidebar({ initialPath: '/dashboard/ward/ward-1' });

      // Ward Dashboards submenu should be auto-expanded
      expect(screen.getByText('Ward North')).toBeInTheDocument();
      expect(screen.getByText('Ward South')).toBeInTheDocument();
    });

    it('should keep submenu expanded when clicking another child in same submenu', () => {
      // Start on a ward dashboard page
      renderSidebar({ initialPath: '/dashboard/ward/ward-1' });

      // Both children should be visible (submenu expanded)
      const wardNorth = screen.getByText('Ward North');
      const wardSouth = screen.getByText('Ward South');
      expect(wardNorth).toBeInTheDocument();
      expect(wardSouth).toBeInTheDocument();

      // Click on Ward South
      fireEvent.click(wardSouth);

      // Submenu should still be expanded (both children visible)
      expect(screen.getByText('Ward North')).toBeInTheDocument();
      expect(screen.getByText('Ward South')).toBeInTheDocument();
    });

    it('should close other submenus when opening a different one', async () => {
      renderSidebar();

      // Expand Ward Dashboards
      const wardDashboardsButton = screen.getByRole('button', { name: /ward dashboards/i });
      fireEvent.click(wardDashboardsButton);

      // Ward children should be visible
      expect(screen.getByText('Ward North')).toBeInTheDocument();

      // Expand Sector Dashboards
      const sectorDashboardsButton = screen.getByRole('button', { name: /sector dashboards/i });
      fireEvent.click(sectorDashboardsButton);

      // Sector children should be visible
      expect(screen.getByText('Sector A')).toBeInTheDocument();

      // Ward children should be hidden (submenu closed) - wait for collapse animation
      await waitFor(() => {
        expect(screen.queryByText('Ward North')).not.toBeInTheDocument();
      });
    });

    it('should toggle submenu closed when clicking on expanded parent', async () => {
      renderSidebar();

      const wardDashboardsButton = screen.getByRole('button', { name: /ward dashboards/i });

      // Expand
      fireEvent.click(wardDashboardsButton);
      expect(screen.getByText('Ward North')).toBeInTheDocument();

      // Collapse
      fireEvent.click(wardDashboardsButton);

      // Wait for collapse animation
      await waitFor(() => {
        expect(screen.queryByText('Ward North')).not.toBeInTheDocument();
      });
    });
  });

  describe('active parent auto-expansion', () => {
    it('should auto-expand ward submenu when on ward dashboard page', () => {
      renderSidebar({ initialPath: '/dashboard/ward/ward-1' });

      // Ward children should be visible without user interaction
      expect(screen.getByText('Ward North')).toBeInTheDocument();
      expect(screen.getByText('Ward South')).toBeInTheDocument();
    });

    it('should auto-expand sector submenu when on sector dashboard page', () => {
      renderSidebar({ initialPath: '/dashboard/sector/sector-1' });

      // Sector children should be visible without user interaction
      expect(screen.getByText('Sector A')).toBeInTheDocument();
      expect(screen.getByText('Sector B')).toBeInTheDocument();
    });

    it('should not auto-expand any submenu when on main dashboard', () => {
      renderSidebar({ initialPath: '/' });

      // No submenu children should be visible
      expect(screen.queryByText('Ward North')).not.toBeInTheDocument();
      expect(screen.queryByText('Sector A')).not.toBeInTheDocument();
    });
  });

  describe('navigation items', () => {
    it('should render all Pod Chief navigation items', () => {
      renderSidebar();

      expect(screen.getByRole('link', { name: /^dashboard$/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /ward dashboards/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /sector dashboards/i })).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /pod administrators/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /reports/i })).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /messages/i })).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /pod settings/i })).toBeInTheDocument();
    });

    it('should highlight active navigation item', () => {
      renderSidebar({ initialPath: '/messages' });

      const messagesLink = screen.getByRole('link', { name: /messages/i });
      expect(messagesLink).toHaveClass('Mui-selected');
    });
  });
});
