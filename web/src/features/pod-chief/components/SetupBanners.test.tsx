import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter } from 'react-router-dom';

import type { SetupStep } from '@/shared/hooks/usePodSetup';
import { SetupBanners } from './SetupBanners';

// Mock navigation
const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  };
});

// Mock i18n
vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const translations: Record<string, string> = {
        'common.configure': 'Configure',
        'podChief.setup.podName': 'Set Pod Name',
        'podChief.setup.podNameDescription':
          "Configure your pod's display name that appears in the header.",
        'podChief.setup.podBoundaries': 'Configure Pod Boundaries',
        'podChief.setup.podBoundariesDescription':
          'Define the geographic boundaries of your pod on the map.',
        'podChief.setup.wardsSectors': 'Set Up Wards/Sectors',
        'podChief.setup.wardsSectorsDescription':
          'Create the organizational structure for your pod.',
        'podChief.setup.firstAdmin': 'Add First Administrator',
        'podChief.setup.firstAdminDescription':
          'Invite your first pod administrator to help manage the pod.',
      };
      return translations[key] ?? key;
    },
  }),
}));

const renderWithRouter = (ui: React.ReactElement) => {
  return render(<MemoryRouter>{ui}</MemoryRouter>);
};

describe('SetupBanners', () => {
  beforeEach(() => {
    mockNavigate.mockClear();
  });

  it('renders nothing when missingSteps is empty', () => {
    const { container } = renderWithRouter(<SetupBanners missingSteps={[]} />);
    expect(container.firstChild).toBeNull();
  });

  it('renders a banner for each missing step', () => {
    const missingSteps: SetupStep[] = ['pod_name', 'first_admin'];
    renderWithRouter(<SetupBanners missingSteps={missingSteps} />);

    expect(screen.getByText('Set Pod Name')).toBeInTheDocument();
    expect(screen.getByText('Add First Administrator')).toBeInTheDocument();
  });

  it('renders all four banners when all steps are missing', () => {
    const missingSteps: SetupStep[] = [
      'pod_name',
      'pod_boundaries',
      'wards_sectors',
      'first_admin',
    ];
    renderWithRouter(<SetupBanners missingSteps={missingSteps} />);

    expect(screen.getByText('Set Pod Name')).toBeInTheDocument();
    expect(screen.getByText('Configure Pod Boundaries')).toBeInTheDocument();
    expect(screen.getByText('Set Up Wards/Sectors')).toBeInTheDocument();
    expect(screen.getByText('Add First Administrator')).toBeInTheDocument();
  });

  it('navigates to settings when pod_name configure button is clicked', async () => {
    const user = userEvent.setup();
    renderWithRouter(<SetupBanners missingSteps={['pod_name']} />);

    const configureButton = screen.getByRole('button', { name: /configure/i });
    await user.click(configureButton);

    expect(mockNavigate).toHaveBeenCalledWith('/settings/pod');
  });

  it('navigates to administrators when first_admin configure button is clicked', async () => {
    const user = userEvent.setup();
    renderWithRouter(<SetupBanners missingSteps={['first_admin']} />);

    const configureButton = screen.getByRole('button', { name: /configure/i });
    await user.click(configureButton);

    expect(mockNavigate).toHaveBeenCalledWith('/pod-administrators');
  });

  it('renders banner descriptions', () => {
    renderWithRouter(<SetupBanners missingSteps={['pod_name']} />);

    expect(
      screen.getByText(
        "Configure your pod's display name that appears in the header."
      )
    ).toBeInTheDocument();
  });

  it('renders banners in the correct order based on missingSteps array', () => {
    const missingSteps: SetupStep[] = ['first_admin', 'pod_name'];
    renderWithRouter(<SetupBanners missingSteps={missingSteps} />);

    const alerts = screen.getAllByRole('alert');
    expect(alerts).toHaveLength(2);

    // First banner should be first_admin (as per array order)
    expect(alerts[0]).toHaveTextContent('Add First Administrator');
    expect(alerts[1]).toHaveTextContent('Set Pod Name');
  });
});
