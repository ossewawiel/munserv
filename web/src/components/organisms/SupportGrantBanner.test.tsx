import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Link } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import { http, HttpResponse, delay } from 'msw';
import i18n from 'i18next';

import { server } from '@/test/mocks/server';
import { SupportGrantBanner } from './SupportGrantBanner';

const mockUseAuth = vi.fn();
vi.mock('@/shared/hooks/useAuth', () => ({
  useAuth: () => mockUseAuth(),
}));

i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
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

const theme = createTheme();

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
      mutations: { retry: false },
    },
  });
}

function bannerText(): string {
  const label = document.querySelector('.MuiChip-label');
  return label?.textContent ?? '';
}

function Harness({ initialRoute = '/dashboard' }: { initialRoute?: string }) {
  const queryClient = createTestQueryClient();

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter initialEntries={[initialRoute]}>
            <SupportGrantBanner />
            <Link to="/settings">Go to settings</Link>
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('SupportGrantBanner', () => {
  beforeEach(() => {
    mockUseAuth.mockReset();
    server.resetHandlers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('should render nothing when there is no support grant', () => {
    mockUseAuth.mockReturnValue({ supportGrant: null });

    const { container } = render(<Harness />);

    expect(container.querySelector('.MuiChip-root')).not.toBeInTheDocument();
  });

  it('should count down to the server expiry', async () => {
    const fixedNow = new Date('2026-09-05T10:00:00Z').getTime();
    vi.useFakeTimers({ shouldAdvanceTime: true });
    vi.setSystemTime(fixedNow);

    const grantExpiresAt = new Date(fixedNow + 10 * 60 * 1000).toISOString();
    mockUseAuth.mockReturnValue({
      supportGrant: {
        grantId: 'grant-1',
        grantedRole: 'pod_admin',
        expiresAt: grantExpiresAt,
      },
    });

    // The current-grant fetch settles to the same expiry as the stored grant,
    // so the assertions hold whether or not it has resolved yet.
    server.use(
      http.get('*/support-access/grants/current', async () => {
        await delay(20);
        return HttpResponse.json({ expiresAt: grantExpiresAt });
      })
    );

    render(<Harness />);

    expect(bannerText()).toContain('10:00 left');

    await act(async () => {
      vi.advanceTimersByTime(65 * 1000);
    });

    await waitFor(() => {
      expect(bannerText()).toContain('08:55 left');
    });
  });

  it('should show the slid expiry after a route change', async () => {
    const fixedNow = new Date('2026-09-05T10:00:00Z').getTime();
    vi.useFakeTimers({ shouldAdvanceTime: true });
    vi.setSystemTime(fixedNow);

    mockUseAuth.mockReturnValue({
      supportGrant: {
        grantId: 'grant-1',
        grantedRole: 'pod_admin',
        expiresAt: new Date(fixedNow + 10 * 60 * 1000).toISOString(),
      },
    });

    server.use(
      http.get('*/support-access/grants/current', async () => {
        await delay(20);
        return HttpResponse.json({ expiresAt: new Date(fixedNow + 60 * 60 * 1000).toISOString() });
      })
    );

    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

    render(<Harness />);

    expect(bannerText()).toContain('10:00 left');

    await user.click(screen.getByRole('link', { name: /go to settings/i }));

    await waitFor(() => {
      expect(bannerText()).toContain('60:00 left');
    });
  });
});
