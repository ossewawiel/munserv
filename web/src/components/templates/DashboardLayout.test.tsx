import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { DashboardLayout } from './DashboardLayout';

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

// Mock useLogout and useCurrentSupportGrant
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

// Mock i18n constants
vi.mock('@/lib/i18n', () => ({
  SUPPORTED_LANGUAGES: ['en'] as const,
  LANGUAGE_NAMES: { en: 'English' },
  LANGUAGE_NATIVE_NAMES: { en: 'English' },
}));

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: { appName: 'MunServ Admin', loading: 'Loading...' },
        auth: { logout: 'Logout' },
        profile: {
          menuTrigger: 'Profile menu',
          greeting: {
            morning: 'Good morning',
            afternoon: 'Good afternoon',
            evening: 'Good evening',
          },
          mood: 'Mood',
          moodLight: 'Light',
          moodDark: 'Dark',
          moodSystem: 'System',
          language: 'Language',
        },
        nav: {
          dashboard: 'Dashboard',
          issues: 'Issues',
          heatReport: 'Heat Report',
          members: 'Members',
        },
        roles: { pod_admin: 'Pod Admin' },
        supportGrant: {
          banner: 'Support access as {{role}} · <time>{{remaining}}</time> left',
          remainingLabel: 'Time remaining',
          expired: 'Support access expired',
        },
      },
    },
  },
});

const lightTheme = createTheme({
  palette: {
    mode: 'light',
    primary: { main: '#0C2721' },
    divider: '#C1C8C4',
  },
});

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
    primary: { main: '#B0CDC3' },
    divider: '#3A4742',
  },
});

// Mock matchMedia for responsive breakpoints
function mockMatchMedia(prefersDark: boolean) {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      matches: query === '(prefers-color-scheme: dark)' ? prefersDark : false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    })),
  });
}

interface RenderOptions {
  theme?: ReturnType<typeof createTheme>;
  colorMode?: 'light' | 'dark' | 'system';
  prefersDarkMode?: boolean;
}

function renderWithProviders(
  ui: React.ReactElement,
  { theme = lightTheme, colorMode = 'light', prefersDarkMode = false }: RenderOptions = {}
) {
  mockUseThemeContext.mockReturnValue({
    colorMode,
    setColorMode: vi.fn(),
    podConfig: { podId: 'test', fonts: { primary: 'Roboto' }, colors: {} },
    isLoading: false,
  });
  mockMatchMedia(prefersDarkMode);

  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter>{ui}</MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

beforeEach(() => {
  mockUseThemeContext.mockReset();
  mockUseAuth.mockReset();
  mockUseAuth.mockReturnValue({ supportGrant: null });
});

describe('DashboardLayout', () => {
  describe('layout structure', () => {
    it('should render AppBar with ProfileMenu', () => {
      renderWithProviders(
        <DashboardLayout>
          <div>Content</div>
        </DashboardLayout>
      );

      // AppBar contains the hamburger menu and profile menu button
      expect(screen.getByRole('button', { name: /profile/i })).toBeInTheDocument();
    });

    it('should render children content', () => {
      renderWithProviders(
        <DashboardLayout>
          <div data-testid="dashboard-content">Dashboard content</div>
        </DashboardLayout>
      );

      expect(screen.getByTestId('dashboard-content')).toBeInTheDocument();
    });

    it('should render main content area', () => {
      const { container } = renderWithProviders(
        <DashboardLayout>
          <div>Content</div>
        </DashboardLayout>
      );

      const mainElement = container.querySelector('main');
      expect(mainElement).toBeInTheDocument();
    });

    it('should show the support grant banner when a grant is stored', () => {
      mockUseAuth.mockReturnValue({
        supportGrant: {
          grantId: 'grant-1',
          grantedRole: 'pod_admin',
          expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
        },
      });

      const { container } = renderWithProviders(
        <DashboardLayout>
          <div>Content</div>
        </DashboardLayout>
      );

      expect(container.querySelector('.MuiChip-root')).toBeInTheDocument();
    });
  });

  describe('content area styling', () => {
    it('should render main element as the content area', () => {
      const { container } = renderWithProviders(
        <DashboardLayout>
          <div>Content</div>
        </DashboardLayout>,
        { theme: lightTheme }
      );

      const mainElement = container.querySelector('main');
      expect(mainElement).toBeInTheDocument();
      // Main element is a styled component that applies border styling
      // Visual verification: borders separate content from nav areas
    });

    it('should render main element with emotion class for styling', () => {
      const { container } = renderWithProviders(
        <DashboardLayout>
          <div>Content</div>
        </DashboardLayout>,
        { theme: lightTheme }
      );

      const mainElement = container.querySelector('main');
      expect(mainElement).toBeInTheDocument();
      // Styled components apply CSS class - check it has some class applied
      expect(mainElement?.className).toBeTruthy();
    });
  });

  describe('theme modes', () => {
    it('should render in light mode', () => {
      const { container } = renderWithProviders(
        <DashboardLayout>
          <div>Content</div>
        </DashboardLayout>,
        { theme: lightTheme, colorMode: 'light' }
      );

      const mainElement = container.querySelector('main');
      expect(mainElement).toBeInTheDocument();
    });

    it('should render in dark mode', () => {
      const { container } = renderWithProviders(
        <DashboardLayout>
          <div>Content</div>
        </DashboardLayout>,
        { theme: darkTheme, colorMode: 'dark' }
      );

      const mainElement = container.querySelector('main');
      expect(mainElement).toBeInTheDocument();
    });
  });
});
