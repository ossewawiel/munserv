import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import { vi } from 'vitest';

import { PodSettingsPage } from './PodSettingsPage';

vi.mock('@/components/templates/DashboardLayout', () => ({
  DashboardLayout: ({ children }: { children: ReactNode }) => <div>{children}</div>,
}));

vi.mock('@/components/molecules/Breadcrumbs', () => ({
  Breadcrumbs: () => null,
}));

vi.mock('@/features/support-access/SupportAccessSection', () => ({
  SupportAccessSection: () => <div data-testid="support-access-section">Support access</div>,
}));

function renderWithProviders(ui: ReactNode) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });

  return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>);
}

describe('PodSettingsPage', () => {
  it('should show the pod identity section above support access', async () => {
    renderWithProviders(<PodSettingsPage />);

    const identityHeading = await screen.findByRole('heading', { name: /pod identity/i });
    const supportSection = screen.getByTestId('support-access-section');

    expect(identityHeading.compareDocumentPosition(supportSection) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });
});
