import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { LocationPickerDialog } from './LocationPickerDialog';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        auth: {
          selectLocation: 'Select Your Location',
          selectLocationHelp: 'Click on the map or drag the marker to select your address',
          currentLocation: 'Current Location',
          selectedAddress: 'Selected Address',
          confirmLocation: 'Confirm Location',
          loadingMap: 'Loading map...',
          mapLoadError: 'Could not load map. Please try again.',
          gettingLocation: 'Getting your location...',
          gettingAddress: 'Getting address...',
          locationError: 'Could not get your location',
        },
        common: {
          cancel: 'Cancel',
          close: 'Close',
        },
      },
    },
  },
});

const theme = createTheme();

// Mock react-leaflet components
vi.mock('react-leaflet', () => ({
  MapContainer: vi.fn(({ children }) => (
    <div data-testid="leaflet-map">{children}</div>
  )),
  TileLayer: vi.fn(() => null),
  Marker: vi.fn(() => <div data-testid="leaflet-marker" />),
  useMapEvents: vi.fn((handlers) => {
    // Store handlers for testing
    (window as unknown as Record<string, unknown>).__mapEventHandlers = handlers;
    return null;
  }),
  useMap: vi.fn(() => ({
    setView: vi.fn(),
    getZoom: vi.fn(() => 15),
  })),
}));

// Mock Leaflet
vi.mock('leaflet', () => ({
  default: {
    Icon: {
      Default: {
        prototype: {},
        mergeOptions: vi.fn(),
      },
    },
  },
}));

// Mock Leaflet CSS import
vi.mock('leaflet/dist/leaflet.css', () => ({}));

// Mock marker images
vi.mock('leaflet/dist/images/marker-icon-2x.png', () => ({ default: 'marker-icon-2x.png' }));
vi.mock('leaflet/dist/images/marker-icon.png', () => ({ default: 'marker-icon.png' }));
vi.mock('leaflet/dist/images/marker-shadow.png', () => ({ default: 'marker-shadow.png' }));

// Mock geolocation
function mockGeolocation(options: { success?: boolean; coords?: { latitude: number; longitude: number } } = {}) {
  const { success = true, coords = { latitude: -26.2041, longitude: 28.0473 } } = options;

  const mockGeolocationAPI = {
    getCurrentPosition: vi.fn((successCallback, errorCallback) => {
      if (success) {
        successCallback({ coords });
      } else {
        errorCallback({ code: 1, message: 'User denied geolocation' });
      }
    }),
  };

  Object.defineProperty(navigator, 'geolocation', {
    value: mockGeolocationAPI,
    writable: true,
  });

  return mockGeolocationAPI;
}

// Mock fetch for Nominatim geocoding
function mockNominatimFetch(address: string = '123 Test Street, Johannesburg, South Africa') {
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    json: () => Promise.resolve({ display_name: address }),
  });
}

function renderLocationPickerDialog(props: Partial<React.ComponentProps<typeof LocationPickerDialog>> = {}) {
  const defaultProps = {
    open: true,
    onClose: vi.fn(),
    onConfirm: vi.fn(),
    initialLatitude: undefined,
    initialLongitude: undefined,
  };

  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <LocationPickerDialog {...defaultProps} {...props} />
      </I18nextProvider>
    </ThemeProvider>
  );
}

describe('LocationPickerDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockNominatimFetch();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('rendering', () => {
    it('should render dialog when open is true', () => {
      renderLocationPickerDialog({ open: true });

      expect(screen.getByRole('dialog')).toBeInTheDocument();
      expect(screen.getByText('Select Your Location')).toBeInTheDocument();
    });

    it('should not render dialog when open is false', () => {
      renderLocationPickerDialog({ open: false });

      expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    });

    it('should render Leaflet map component', () => {
      renderLocationPickerDialog();

      expect(screen.getByTestId('leaflet-map')).toBeInTheDocument();
    });

    it('should render help text', () => {
      renderLocationPickerDialog();

      expect(screen.getByText(/click on the map or drag the marker/i)).toBeInTheDocument();
    });

    it('should render cancel and confirm buttons', () => {
      renderLocationPickerDialog();

      expect(screen.getByRole('button', { name: /cancel/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /confirm location/i })).toBeInTheDocument();
    });

    it('should render current location button', () => {
      renderLocationPickerDialog();

      expect(screen.getByRole('button', { name: /current location/i })).toBeInTheDocument();
    });
  });

  describe('geolocation', () => {
    it('should get current location when current location button is clicked', async () => {
      const mockGeo = mockGeolocation({ success: true, coords: { latitude: -26.5, longitude: 28.5 } });
      renderLocationPickerDialog();

      const currentLocationBtn = screen.getByRole('button', { name: /current location/i });
      await userEvent.click(currentLocationBtn);

      await waitFor(() => {
        expect(mockGeo.getCurrentPosition).toHaveBeenCalled();
      });
    });

    it('should show error when geolocation fails', async () => {
      mockGeolocation({ success: false });
      renderLocationPickerDialog();

      const currentLocationBtn = screen.getByRole('button', { name: /current location/i });
      await userEvent.click(currentLocationBtn);

      await waitFor(() => {
        expect(screen.getByText(/could not get your location/i)).toBeInTheDocument();
      });
    });

    it('should use initial coordinates when provided', () => {
      renderLocationPickerDialog({
        initialLatitude: -26.1,
        initialLongitude: 28.1,
      });

      expect(screen.getByTestId('leaflet-map')).toBeInTheDocument();
    });
  });

  describe('address selection', () => {
    it('should call Nominatim API for reverse geocoding', async () => {
      mockNominatimFetch('123 Test Street, Johannesburg, South Africa');
      mockGeolocation({ success: true });
      renderLocationPickerDialog();

      await userEvent.click(screen.getByRole('button', { name: /current location/i }));

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          expect.stringContaining('nominatim.openstreetmap.org/reverse'),
          expect.any(Object)
        );
      });
    });

    it('should display selected address after reverse geocoding', async () => {
      mockNominatimFetch('123 Test Street, Johannesburg, South Africa');
      mockGeolocation({ success: true });
      renderLocationPickerDialog();

      await userEvent.click(screen.getByRole('button', { name: /current location/i }));

      await waitFor(() => {
        expect(screen.getByText(/123 Test Street/i)).toBeInTheDocument();
      });
    });

    it('should show selected address label', async () => {
      mockNominatimFetch('456 Main Road, Pretoria');
      mockGeolocation({ success: true });
      renderLocationPickerDialog();

      await userEvent.click(screen.getByRole('button', { name: /current location/i }));

      await waitFor(() => {
        expect(screen.getByText('Selected Address')).toBeInTheDocument();
      });
    });
  });

  describe('confirmation', () => {
    it('should call onConfirm with coordinates and address when confirm is clicked', async () => {
      const onConfirm = vi.fn();
      mockNominatimFetch('123 Test Street, Johannesburg');
      mockGeolocation({ success: true, coords: { latitude: -26.2041, longitude: 28.0473 } });
      renderLocationPickerDialog({ onConfirm });

      // Get current location to set coordinates
      await userEvent.click(screen.getByRole('button', { name: /current location/i }));

      await waitFor(() => {
        expect(screen.getByText(/123 Test Street/i)).toBeInTheDocument();
      });

      // Confirm selection
      await userEvent.click(screen.getByRole('button', { name: /confirm location/i }));

      await waitFor(() => {
        expect(onConfirm).toHaveBeenCalledWith({
          latitude: -26.2041,
          longitude: 28.0473,
          address: '123 Test Street, Johannesburg',
        });
      });
    });

    it('should disable confirm button when no location is selected', () => {
      renderLocationPickerDialog();

      const confirmBtn = screen.getByRole('button', { name: /confirm location/i });
      expect(confirmBtn).toBeDisabled();
    });

    it('should enable confirm button when location is selected', async () => {
      mockNominatimFetch('Test Address');
      mockGeolocation({ success: true });
      renderLocationPickerDialog();

      await userEvent.click(screen.getByRole('button', { name: /current location/i }));

      await waitFor(() => {
        const confirmBtn = screen.getByRole('button', { name: /confirm location/i });
        expect(confirmBtn).not.toBeDisabled();
      });
    });
  });

  describe('cancellation', () => {
    it('should call onClose when cancel button is clicked', async () => {
      const onClose = vi.fn();
      renderLocationPickerDialog({ onClose });

      await userEvent.click(screen.getByRole('button', { name: /cancel/i }));

      expect(onClose).toHaveBeenCalled();
    });

    it('should call onClose when dialog backdrop is clicked', async () => {
      const onClose = vi.fn();
      renderLocationPickerDialog({ onClose });

      // Press Escape to close dialog
      const dialog = screen.getByRole('dialog');
      fireEvent.keyDown(dialog, { key: 'Escape' });

      await waitFor(() => {
        expect(onClose).toHaveBeenCalled();
      });
    });
  });
});
