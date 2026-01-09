import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import i18n from 'i18next';

import { LoginPage } from './LoginPage';

// Mock useThemeContext
const mockUseThemeContext = vi.fn();
vi.mock('@/theme', async () => {
  const actual = await vi.importActual('@/theme');
  return {
    ...actual,
    useThemeContext: () => mockUseThemeContext(),
  };
});

// Mock useAuth
const mockUseAuth = vi.fn();
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => mockUseAuth(),
}));

// Mock matchMedia for prefers-color-scheme
function mockMatchMedia(prefersDark: boolean = false) {
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

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: { appName: 'MunServ Admin' },
        auth: {
          welcomeBack: 'Hi, Welcome Back',
          enterCredentials: 'Enter your credentials to continue',
          email: 'Email',
          password: 'Password',
          loginButton: 'Sign In',
          loginError: 'Invalid email or password',
          loggingIn: 'Signing in...',
          or: 'or',
          newMember: 'New to the community?',
          registerAsNewMember: 'Register as a New Member',
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
  isAuthenticated?: boolean;
}

function renderLoginPage({ initialRoute = '/login', isAuthenticated = false }: RenderOptions = {}) {
  const queryClient = createTestQueryClient();

  mockUseThemeContext.mockReturnValue({
    colorMode: 'light',
    setColorMode: vi.fn(),
    podConfig: { podId: 'test', fonts: { primary: 'Roboto' }, colors: {} },
    isLoading: false,
  });
  mockMatchMedia(false);
  mockUseAuth.mockReturnValue({
    isAuthenticated,
    admin: null,
    login: vi.fn(),
    logout: vi.fn(),
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter initialEntries={[initialRoute]}>
            <Routes>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<div data-testid="register-page">Register Page</div>} />
              <Route path="/" element={<div data-testid="dashboard">Dashboard</div>} />
            </Routes>
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  describe('rendering', () => {
    it('should render the login form', async () => {
      renderLoginPage();

      await waitFor(() => {
        expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
      });
    });
  });

  describe('register link section', () => {
    it('should render a divider with "or" text', async () => {
      renderLoginPage();

      await waitFor(() => {
        expect(screen.getByText('or')).toBeInTheDocument();
      });
    });

    it('should render "New to the community?" text', async () => {
      renderLoginPage();

      await waitFor(() => {
        expect(screen.getByText('New to the community?')).toBeInTheDocument();
      });
    });

    it('should render "Register as a New Member" button', async () => {
      renderLoginPage();

      await waitFor(() => {
        expect(screen.getByRole('link', { name: /register as a new member/i })).toBeInTheDocument();
      });
    });

    it('should have the register button link to /register', async () => {
      renderLoginPage();

      await waitFor(() => {
        const registerLink = screen.getByRole('link', { name: /register as a new member/i });
        expect(registerLink).toHaveAttribute('href', '/register');
      });
    });
  });

  describe('navigation', () => {
    it('should navigate to register page when register button is clicked', async () => {
      renderLoginPage();

      await waitFor(() => {
        expect(screen.getByRole('link', { name: /register as a new member/i })).toBeInTheDocument();
      });

      await userEvent.click(screen.getByRole('link', { name: /register as a new member/i }));

      await waitFor(() => {
        expect(screen.getByTestId('register-page')).toBeInTheDocument();
      });
    });

    it('should redirect to dashboard if already authenticated', async () => {
      renderLoginPage({ isAuthenticated: true });

      await waitFor(() => {
        expect(screen.getByTestId('dashboard')).toBeInTheDocument();
      });
    });
  });
});
