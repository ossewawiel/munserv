import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import { vi } from 'vitest';

import type { PodSetupState } from '@/shared/hooks/usePodSetup';
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

let mockPodSetup: PodSetupState = {
  status: {
    isComplete: true,
    missingSteps: [],
    wards: [{ id: 'ward-1', name: 'Test Ward North' }],
    sectors: [],
  },
  isSetupComplete: true,
  showAreaDashboards: true,
  showPodAdmins: true,
  isPodLevel: true,
  isLoading: false,
};

vi.mock('@/shared/hooks/usePodSetup', () => ({
  usePodSetup: () => mockPodSetup,
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

  it('should show a pod boundaries placeholder', async () => {
    renderWithProviders(<PodSettingsPage />);

    expect(await screen.findByRole('heading', { name: /pod boundaries/i })).toBeInTheDocument();
  });

  it('should label the area placeholder Ward Boundaries when the pod has wards', async () => {
    mockPodSetup = {
      ...mockPodSetup,
      status: {
        isComplete: true,
        missingSteps: [],
        wards: [{ id: 'ward-1', name: 'Test Ward North' }],
        sectors: [],
      },
    };

    renderWithProviders(<PodSettingsPage />);

    expect(await screen.findByRole('heading', { name: /ward boundaries/i })).toBeInTheDocument();
  });

  it('should label the area placeholder Sector Boundaries when the pod has no wards', async () => {
    mockPodSetup = {
      ...mockPodSetup,
      status: {
        isComplete: true,
        missingSteps: [],
        wards: [],
        sectors: [{ id: 'sector-1', name: 'Ward 42 - Northcliff' }],
      },
    };

    renderWithProviders(<PodSettingsPage />);

    expect(await screen.findByRole('heading', { name: /sector boundaries/i })).toBeInTheDocument();
  });
});
