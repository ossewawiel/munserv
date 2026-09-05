import '@/lib/i18n';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { SupportAccessSection } from './SupportAccessSection';
import { formatDateTime } from '@/shared/utils/formatters';
import type { SupportGrant } from './types';
import type { ReactNode } from 'react';

function renderWithClient(ui: ReactNode) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
      mutations: { retry: false },
    },
  });
  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>);
}

const activeGrant: SupportGrant = {
  id: 'grant-active',
  grantedRole: 'pod_admin',
  purpose: 'Investigate duplicate issue reports in sector 3',
  status: 'active',
  grantedBy: 'admin-1',
  grantedByName: 'Thandi Mokoena',
  grantedAt: '2026-09-05T09:41:00Z',
  expiresAt: '2026-09-05T10:41:00Z',
  lastActivity: null,
  revokedAt: null,
  expiredAt: null,
};

describe('SupportAccessSection', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    server.resetHandlers();
  });

  it('should disable the grant button when an active grant exists', async () => {
    server.use(
      http.get('*/support-access/grants', () =>
        HttpResponse.json({ items: [activeGrant], total: 1 })
      )
    );

    renderWithClient(<SupportAccessSection />);

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /grant support access/i })).toBeDisabled();
    });
  });

  it('should render the expiry of the active grant', async () => {
    server.use(
      http.get('*/support-access/grants', () =>
        HttpResponse.json({ items: [activeGrant], total: 1 })
      )
    );

    renderWithClient(<SupportAccessSection />);

    const expected = formatDateTime(activeGrant.expiresAt);
    await waitFor(() => {
      expect(within(screen.getByRole('alert')).getByText(expected, { exact: false })).toBeInTheDocument();
    });
  });

  it('should open a fresh dialog each time so a cancelled purpose is not kept', async () => {
    server.use(
      http.get('*/support-access/grants', () => HttpResponse.json({ items: [], total: 0 }))
    );
    const user = userEvent.setup();

    renderWithClient(<SupportAccessSection />);

    await user.click(await screen.findByRole('button', { name: /grant support access/i }));
    await user.type(screen.getByRole('textbox'), 'Abandoned purpose');
    await user.click(screen.getByRole('button', { name: /cancel/i }));
    await waitFor(() => {
      expect(screen.queryByRole('textbox')).not.toBeInTheDocument();
    });

    await user.click(screen.getByRole('button', { name: /grant support access/i }));

    expect(screen.getByRole('textbox')).toHaveValue('');
  });
});
