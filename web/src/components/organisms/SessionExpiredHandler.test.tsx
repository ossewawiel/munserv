import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor, act } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, useLocation } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';
import { http, HttpResponse } from 'msw';
import { useEffect, useState } from 'react';

import { server } from '@/test/mocks/server';
import { SessionExpiredHandler } from './SessionExpiredHandler';
import { apiClient } from '@/lib/api-client';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        auth: {
          sessionExpired: 'Your session has expired',
          redirectingToLogin: 'Redirecting to login...',
        },
      },
    },
  },
});

const theme = createTheme();

// Helper to capture current location
function LocationDisplay() {
  const location = useLocation();
  return <div data-testid="location">{location.pathname}</div>;
}

function createWrapper(initialEntries: string[] = ['/dashboard']) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={initialEntries}>
          <ThemeProvider theme={theme}>
            <I18nextProvider i18n={i18n}>
              {children}
              <LocationDisplay />
            </I18nextProvider>
          </ThemeProvider>
        </MemoryRouter>
      </QueryClientProvider>
    );
  };
}

describe('SessionExpiredHandler', () => {
  beforeEach(() => {
    // Set up localStorage as if user is logged in
    localStorage.setItem('accessToken', 'valid-token');
    localStorage.setItem('refreshToken', 'valid-refresh-token');
    localStorage.setItem('admin', JSON.stringify({ id: '1', email: 'admin@test.com' }));
    vi.useFakeTimers({ shouldAdvanceTime: true });
  });

  afterEach(() => {
    localStorage.clear();
    vi.useRealTimers();
    server.resetHandlers();
  });

  describe('when API returns 401', () => {
    it('should display session expired message', async () => {
      // Override handler to return 401
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json(
            { message: 'Token expired' },
            { status: 401 }
          );
        })
      );

      const Wrapper = createWrapper();
      render(
        <Wrapper>
          <SessionExpiredHandler />
          <TestComponent />
        </Wrapper>
      );

      // Wait for the session expired message to appear
      await waitFor(
        () => {
          expect(screen.getByText(/session has expired/i)).toBeInTheDocument();
        },
        { timeout: 3000 }
      );
    });

    it('should show redirecting message', async () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json(
            { message: 'Token expired' },
            { status: 401 }
          );
        })
      );

      const Wrapper = createWrapper();
      render(
        <Wrapper>
          <SessionExpiredHandler />
          <TestComponent />
        </Wrapper>
      );

      await waitFor(
        () => {
          expect(screen.getByText(/redirecting to login/i)).toBeInTheDocument();
        },
        { timeout: 3000 }
      );
    });

    it('should redirect to login page after delay', async () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json(
            { message: 'Token expired' },
            { status: 401 }
          );
        })
      );

      const Wrapper = createWrapper();
      render(
        <Wrapper>
          <SessionExpiredHandler />
          <TestComponent />
        </Wrapper>
      );

      // Initially should be on dashboard
      expect(screen.getByTestId('location')).toHaveTextContent('/dashboard');

      // Wait for session expired to trigger
      await waitFor(
        () => {
          expect(screen.getByText(/session has expired/i)).toBeInTheDocument();
        },
        { timeout: 3000 }
      );

      // Advance timer to trigger redirect
      await act(async () => {
        vi.advanceTimersByTime(2500);
      });

      // Should be redirected to login
      await waitFor(() => {
        expect(screen.getByTestId('location')).toHaveTextContent('/login');
      });
    });

    it('should clear auth data from localStorage', async () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json(
            { message: 'Token expired' },
            { status: 401 }
          );
        })
      );

      const Wrapper = createWrapper();
      render(
        <Wrapper>
          <SessionExpiredHandler />
          <TestComponent />
        </Wrapper>
      );

      await waitFor(
        () => {
          expect(screen.getByText(/session has expired/i)).toBeInTheDocument();
        },
        { timeout: 3000 }
      );

      // Auth data should be cleared (by api-client interceptor)
      expect(localStorage.getItem('accessToken')).toBeNull();
      expect(localStorage.getItem('refreshToken')).toBeNull();
      expect(localStorage.getItem('admin')).toBeNull();
    });

    it('should only show one notification for multiple concurrent 401 errors', async () => {
      server.use(
        http.get('*/issues', () => {
          return HttpResponse.json({ message: 'Token expired' }, { status: 401 });
        }),
        http.get('*/members', () => {
          return HttpResponse.json({ message: 'Token expired' }, { status: 401 });
        })
      );

      const Wrapper = createWrapper();
      render(
        <Wrapper>
          <SessionExpiredHandler />
          <TestComponentMultipleRequests />
        </Wrapper>
      );

      await waitFor(
        () => {
          expect(screen.getByText(/session has expired/i)).toBeInTheDocument();
        },
        { timeout: 3000 }
      );

      // Should only have one snackbar
      const messages = screen.getAllByText(/session has expired/i);
      expect(messages).toHaveLength(1);
    });
  });

  describe('when API returns 403 (Forbidden)', () => {
    it('should display session expired message and redirect', async () => {
      server.use(
        http.get('*/admin/dashboard', () => {
          return HttpResponse.json(
            { error: 'Forbidden', message: 'Access Denied' },
            { status: 403 }
          );
        })
      );

      const Wrapper = createWrapper();
      render(
        <Wrapper>
          <SessionExpiredHandler />
          <TestComponentDashboard />
        </Wrapper>
      );

      await waitFor(
        () => {
          expect(screen.getByText(/session has expired/i)).toBeInTheDocument();
        },
        { timeout: 3000 }
      );

      // Auth data should be cleared
      expect(localStorage.getItem('accessToken')).toBeNull();
    });
  });

  describe('when user is on login page', () => {
    it('should NOT show session expired for 401 on login attempt', async () => {
      server.use(
        http.post('*/auth/admin/login', () => {
          return HttpResponse.json(
            { message: 'Invalid credentials' },
            { status: 401 }
          );
        })
      );

      const Wrapper = createWrapper(['/login']);
      render(
        <Wrapper>
          <SessionExpiredHandler />
          <TestLoginComponent />
        </Wrapper>
      );

      // Wait a bit to ensure no session expired message appears
      await act(async () => {
        vi.advanceTimersByTime(500);
      });

      expect(screen.queryByText(/session has expired/i)).not.toBeInTheDocument();
    });
  });
});

// Test component that triggers an API call
function TestComponent() {
  const [, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchIssues = async () => {
      try {
        await apiClient.get('/issues');
      } catch (err) {
        setError(err as Error);
      }
    };

    fetchIssues();
  }, []);

  return <div>Test Component</div>;
}

// Test component that triggers multiple API calls
function TestComponentMultipleRequests() {
  const [, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        await Promise.all([
          apiClient.get('/issues'),
          apiClient.get('/members'),
        ]);
      } catch (err) {
        setError(err as Error);
      }
    };

    fetchData();
  }, []);

  return <div>Test Component</div>;
}

// Test component that simulates login attempt
function TestLoginComponent() {
  const [, setError] = useState<Error | null>(null);

  useEffect(() => {
    const attemptLogin = async () => {
      try {
        await apiClient.post('/auth/admin/login', {
          email: 'test@test.com',
          password: 'wrong',
        });
      } catch (err) {
        setError(err as Error);
      }
    };

    attemptLogin();
  }, []);

  return <div>Login Component</div>;
}

// Test component that triggers dashboard API call
function TestComponentDashboard() {
  const [, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchDashboard = async () => {
      try {
        await apiClient.get('/admin/dashboard');
      } catch (err) {
        setError(err as Error);
      }
    };

    fetchDashboard();
  }, []);

  return <div>Dashboard Component</div>;
}
