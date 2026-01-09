import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { RegisterForm } from './RegisterForm';
import type { Sector } from '@/features/auth/types';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        auth: {
          personalInfo: 'Personal Information',
          contactInfo: 'Contact Information',
          locationInfo: 'Location Information',
          firstName: 'First Name',
          surname: 'Surname',
          email: 'Email Address',
          emailHelp: "You'll use this email to log in to the mobile app",
          phone: 'Phone Number',
          phoneHelp: 'For contact purposes',
          address: 'Street Address',
          sector: 'Community/Ward',
          sectorHelp: 'Select the community you belong to',
          getLocation: 'Get My Location',
          gettingLocation: 'Getting location...',
          locationCaptured: 'Location captured',
          locationError: 'Could not get location. Please try again.',
          locationRequired: 'Please capture your location using the button above',
          submitRegistration: 'Submit Registration',
        },
        validation: {
          required: 'This field is required',
          maxLength: 'Maximum {{max}} characters allowed',
          invalidEmail: 'Please enter a valid email address',
          invalidPhone: 'Please enter a valid phone number (e.g., +27821234567)',
        },
      },
    },
  },
});

const theme = createTheme();

const mockSectors: Sector[] = [
  { id: 'sector-1', name: 'Ward 42', center: { latitude: -26.2041, longitude: 28.0473 } },
  { id: 'sector-2', name: 'Ward 43', center: { latitude: -26.2100, longitude: 28.0500 } },
];

function renderRegisterForm(props: Partial<React.ComponentProps<typeof RegisterForm>> = {}) {
  const defaultProps = {
    sectors: mockSectors,
    onSubmit: vi.fn(),
    isLoading: false,
    error: undefined,
  };

  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>
        <RegisterForm {...defaultProps} {...props} />
      </I18nextProvider>
    </ThemeProvider>
  );
}

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

describe('RegisterForm', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rendering', () => {
    it('should render personal information section', () => {
      renderRegisterForm();

      expect(screen.getByText('Personal Information')).toBeInTheDocument();
      expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/surname/i)).toBeInTheDocument();
    });

    it('should render contact information section', () => {
      renderRegisterForm();

      expect(screen.getByText('Contact Information')).toBeInTheDocument();
      expect(screen.getByLabelText(/email address/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/phone number/i)).toBeInTheDocument();
    });

    it('should render location information section', () => {
      renderRegisterForm();

      expect(screen.getByText('Location Information')).toBeInTheDocument();
      expect(screen.getByLabelText(/street address/i)).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /get my location/i })).toBeInTheDocument();
    });

    it('should render sector dropdown with options', async () => {
      renderRegisterForm();

      const sectorDropdown = screen.getByLabelText(/community\/ward/i);
      expect(sectorDropdown).toBeInTheDocument();

      // Open the dropdown
      await userEvent.click(sectorDropdown);

      // Check options are visible
      await waitFor(() => {
        expect(screen.getByText('Ward 42')).toBeInTheDocument();
        expect(screen.getByText('Ward 43')).toBeInTheDocument();
      });
    });

    it('should render submit button', () => {
      renderRegisterForm();

      expect(screen.getByRole('button', { name: /submit registration/i })).toBeInTheDocument();
    });

    it('should show error message when provided', () => {
      renderRegisterForm({ error: 'Email already registered' });

      expect(screen.getByText('Email already registered')).toBeInTheDocument();
    });

    it('should disable form fields when loading', () => {
      renderRegisterForm({ isLoading: true });

      expect(screen.getByLabelText(/first name/i)).toBeDisabled();
      expect(screen.getByLabelText(/email address/i)).toBeDisabled();
    });
  });

  describe('validation', () => {
    it('should not call onSubmit for empty required fields', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      // React Hook Form prevents submission when validation fails
      await waitFor(() => {
        expect(onSubmit).not.toHaveBeenCalled();
      });
    });

    it('should not submit with invalid email format', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      // Fill only email with invalid format
      const emailInput = screen.getByLabelText(/email address/i);
      await userEvent.type(emailInput, 'invalid-email');
      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      await waitFor(() => {
        expect(onSubmit).not.toHaveBeenCalled();
      });
    });

    it('should not submit with invalid phone format', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      // Fill phone with invalid format
      const phoneInput = screen.getByLabelText(/phone number/i);
      await userEvent.type(phoneInput, '123');
      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      await waitFor(() => {
        expect(onSubmit).not.toHaveBeenCalled();
      });
    });

    it('should show location required alert when coordinates not captured', async () => {
      mockGeolocation({ success: true });
      renderRegisterForm();

      // Fill in all other required fields
      await userEvent.type(screen.getByLabelText(/first name/i), 'John');
      await userEvent.type(screen.getByLabelText(/surname/i), 'Doe');
      await userEvent.type(screen.getByLabelText(/email address/i), 'john@example.com');
      await userEvent.type(screen.getByLabelText(/phone number/i), '+27821234567');
      await userEvent.type(screen.getByLabelText(/street address/i), '123 Main St');

      // Select sector
      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 42'));

      // Submit without capturing location
      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      // The location required alert should appear
      await waitFor(() => {
        expect(screen.getByRole('alert')).toBeInTheDocument();
      });
    });
  });

  describe('geolocation', () => {
    it('should capture location when get location button is clicked', async () => {
      const mockGeo = mockGeolocation({ success: true, coords: { latitude: -26.2041, longitude: 28.0473 } });
      renderRegisterForm();

      await userEvent.click(screen.getByRole('button', { name: /get my location/i }));

      await waitFor(() => {
        expect(mockGeo.getCurrentPosition).toHaveBeenCalled();
      });

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /location captured/i })).toBeInTheDocument();
      });
    });

    it('should show error when geolocation fails', async () => {
      mockGeolocation({ success: false });
      renderRegisterForm();

      await userEvent.click(screen.getByRole('button', { name: /get my location/i }));

      await waitFor(() => {
        expect(screen.getByText(/could not get location/i)).toBeInTheDocument();
      });
    });

    it('should show loading state while getting location', async () => {
      // Mock geolocation with delayed response
      const mockGeolocationAPI = {
        getCurrentPosition: vi.fn(),
      };
      Object.defineProperty(navigator, 'geolocation', {
        value: mockGeolocationAPI,
        writable: true,
      });

      renderRegisterForm();

      fireEvent.click(screen.getByRole('button', { name: /get my location/i }));

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /getting location/i })).toBeInTheDocument();
      });
    });
  });

  describe('form submission', () => {
    it('should call onSubmit with form data when valid', async () => {
      mockGeolocation({ success: true, coords: { latitude: -26.2041, longitude: 28.0473 } });
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      // Fill in form
      await userEvent.type(screen.getByLabelText(/first name/i), 'John');
      await userEvent.type(screen.getByLabelText(/surname/i), 'Doe');
      await userEvent.type(screen.getByLabelText(/email address/i), 'john@example.com');
      await userEvent.type(screen.getByLabelText(/phone number/i), '+27821234567');
      await userEvent.type(screen.getByLabelText(/street address/i), '123 Main St');

      // Select sector
      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 42'));

      // Get location
      await userEvent.click(screen.getByRole('button', { name: /get my location/i }));
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /location captured/i })).toBeInTheDocument();
      });

      // Submit form
      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            firstName: 'John',
            surname: 'Doe',
            email: 'john@example.com',
            phone: '+27821234567',
            address: '123 Main St',
            latitude: -26.2041,
            longitude: 28.0473,
            sectorId: 'sector-1',
          })
        );
      });
    });

    it('should not submit when form is invalid', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      await waitFor(() => {
        expect(onSubmit).not.toHaveBeenCalled();
      });
    });
  });
});
