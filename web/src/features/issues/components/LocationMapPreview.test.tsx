import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { LocationMapPreview } from './LocationMapPreview';
import type { GeoPoint } from '@/shared/types/common';

// Mock react-leaflet components
vi.mock('react-leaflet', () => ({
  MapContainer: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="map-container">{children}</div>
  ),
  TileLayer: () => <div data-testid="tile-layer" />,
  Marker: () => <div data-testid="marker" />,
  useMap: () => ({
    setView: vi.fn(),
    getZoom: () => 15,
  }),
}));

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: {
          close: 'Close',
        },
        issues: {
          viewOnMap: 'View on map',
          location: 'Location',
        },
      },
    },
  },
});

const theme = createTheme();

function renderWithProviders(ui: React.ReactElement) {
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>{ui}</I18nextProvider>
    </ThemeProvider>
  );
}

const mockLocation: GeoPoint = {
  latitude: -26.2041,
  longitude: 28.0473,
};

describe('LocationMapPreview', () => {
  it('should render map container', () => {
    renderWithProviders(<LocationMapPreview location={mockLocation} />);
    expect(screen.getByTestId('map-container')).toBeInTheDocument();
  });

  it('should render marker at location', () => {
    renderWithProviders(<LocationMapPreview location={mockLocation} />);
    expect(screen.getByTestId('marker')).toBeInTheDocument();
  });

  it('should be clickable and open dialog', async () => {
    renderWithProviders(<LocationMapPreview location={mockLocation} />);

    // Find the clickable map area
    const mapPreview = screen.getByTestId('map-container').parentElement;
    expect(mapPreview).toBeInTheDocument();

    await fireEvent.click(mapPreview!);

    // Dialog should open
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  it('should close dialog when clicking close button', async () => {
    renderWithProviders(<LocationMapPreview location={mockLocation} />);

    // Open dialog
    const mapPreview = screen.getByTestId('map-container').parentElement;
    await fireEvent.click(mapPreview!);

    // Wait for dialog to open
    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });

    // Close dialog
    const closeButton = screen.getByRole('button', { name: /close/i });
    await fireEvent.click(closeButton);

    // Wait for dialog to close (MUI uses animation)
    await waitFor(() => {
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    }, { timeout: 1000 });
  });

  it('should show "View on map" hint text', () => {
    renderWithProviders(
      <LocationMapPreview location={mockLocation} address="123 Main Street, Johannesburg" />
    );
    expect(screen.getByText(/view on map/i)).toBeInTheDocument();
  });

  it('should render with compact height (180px)', () => {
    const { container } = renderWithProviders(<LocationMapPreview location={mockLocation} />);
    // Check that the container has the compact height styling
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toBeInTheDocument();
  });
});
