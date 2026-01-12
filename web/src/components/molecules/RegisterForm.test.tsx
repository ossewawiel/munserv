import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { RegisterForm } from './RegisterForm';
import type { Sector } from '@/features/auth/types';

// Mock the LocationPickerDialog component
vi.mock('./LocationPickerDialog', () => ({
  LocationPickerDialog: vi.fn(({ open, onClose, onConfirm }) => {
    if (!open) return null;
    return (
      <div data-testid="location-picker-dialog" role="dialog">
        <button onClick={onClose}>Cancel</button>
        <button
          onClick={() =>
            onConfirm({
              latitude: -26.2041,
              longitude: 28.0473,
              address: '123 Test Street, Johannesburg',
            })
          }
        >
          Confirm Location
        </button>
      </div>
    );
  }),
}));

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
          addressHelp: 'Enter your street address or use the map',
          sector: 'Community/Ward',
          sectorHelp: 'Select the community you belong to',
          getLocation: 'Get Location from Map',
          locationCaptured: 'Location captured',
          locationOptional: 'Location is optional but helps us serve you better',
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
      expect(screen.getByRole('button', { name: /get location from map/i })).toBeInTheDocument();
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

    it('should submit form with address only (no coordinates) - location is optional', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      // Fill in all required fields
      await userEvent.type(screen.getByLabelText(/first name/i), 'John');
      await userEvent.type(screen.getByLabelText(/surname/i), 'Doe');
      await userEvent.type(screen.getByLabelText(/email address/i), 'john@example.com');
      await userEvent.type(screen.getByLabelText(/phone number/i), '+27821234567');
      await userEvent.type(screen.getByLabelText(/street address/i), '123 Main St');

      // Select sector
      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 42'));

      // Submit without capturing location - should succeed
      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            firstName: 'John',
            address: '123 Main St',
            latitude: 0,
            longitude: 0,
          })
        );
      });
    });
  });

  describe('location picker', () => {
    it('should open location picker dialog when get location button is clicked', async () => {
      renderRegisterForm();

      await userEvent.click(screen.getByRole('button', { name: /get location from map/i }));

      await waitFor(() => {
        expect(screen.getByTestId('location-picker-dialog')).toBeInTheDocument();
      });
    });

    it('should close dialog when cancel is clicked', async () => {
      renderRegisterForm();

      // Open dialog
      await userEvent.click(screen.getByRole('button', { name: /get location from map/i }));
      expect(screen.getByTestId('location-picker-dialog')).toBeInTheDocument();

      // Cancel dialog
      await userEvent.click(screen.getByText('Cancel'));

      await waitFor(() => {
        expect(screen.queryByTestId('location-picker-dialog')).not.toBeInTheDocument();
      });
    });

    it('should fill address and capture coordinates when location is confirmed', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      // Fill other required fields
      await userEvent.type(screen.getByLabelText(/first name/i), 'John');
      await userEvent.type(screen.getByLabelText(/surname/i), 'Doe');
      await userEvent.type(screen.getByLabelText(/email address/i), 'john@example.com');
      await userEvent.type(screen.getByLabelText(/phone number/i), '+27821234567');

      // Select sector
      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 42'));

      // Open location picker and confirm
      await userEvent.click(screen.getByRole('button', { name: /get location from map/i }));
      await userEvent.click(screen.getByText('Confirm Location'));

      // Dialog should close and address should be filled
      await waitFor(() => {
        expect(screen.queryByTestId('location-picker-dialog')).not.toBeInTheDocument();
      });

      // Address field should now contain the address from the dialog
      const addressField = screen.getByLabelText(/street address/i);
      expect(addressField).toHaveValue('123 Test Street, Johannesburg');

      // Button should show location captured
      expect(screen.getByRole('button', { name: /location captured/i })).toBeInTheDocument();

      // Submit and verify coordinates are included
      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            address: '123 Test Street, Johannesburg',
            latitude: -26.2041,
            longitude: 28.0473,
          })
        );
      });
    });

    it('should allow editing address after location is captured', async () => {
      renderRegisterForm();

      // Open location picker and confirm
      await userEvent.click(screen.getByRole('button', { name: /get location from map/i }));
      await userEvent.click(screen.getByText('Confirm Location'));

      // Address field should be editable
      const addressField = screen.getByLabelText(/street address/i);
      await userEvent.clear(addressField);
      await userEvent.type(addressField, '456 Different Street');

      expect(addressField).toHaveValue('456 Different Street');
    });
  });

  describe('form submission', () => {
    it('should call onSubmit with form data when valid (with location from map)', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      // Fill in form
      await userEvent.type(screen.getByLabelText(/first name/i), 'John');
      await userEvent.type(screen.getByLabelText(/surname/i), 'Doe');
      await userEvent.type(screen.getByLabelText(/email address/i), 'john@example.com');
      await userEvent.type(screen.getByLabelText(/phone number/i), '+27821234567');

      // Select sector
      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 42'));

      // Get location from map
      await userEvent.click(screen.getByRole('button', { name: /get location from map/i }));
      await userEvent.click(screen.getByText('Confirm Location'));

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
            address: '123 Test Street, Johannesburg',
            latitude: -26.2041,
            longitude: 28.0473,
            sectorId: 'sector-1',
          })
        );
      });
    });

    it('should call onSubmit with form data when valid (address only, no map location)', async () => {
      const onSubmit = vi.fn();
      renderRegisterForm({ onSubmit });

      // Fill in form
      await userEvent.type(screen.getByLabelText(/first name/i), 'Jane');
      await userEvent.type(screen.getByLabelText(/surname/i), 'Smith');
      await userEvent.type(screen.getByLabelText(/email address/i), 'jane@example.com');
      await userEvent.type(screen.getByLabelText(/phone number/i), '+27829876543');
      await userEvent.type(screen.getByLabelText(/street address/i), '456 Oak Avenue');

      // Select sector
      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 43'));

      // Submit form without using map picker
      await userEvent.click(screen.getByRole('button', { name: /submit registration/i }));

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalledWith(
          expect.objectContaining({
            firstName: 'Jane',
            surname: 'Smith',
            email: 'jane@example.com',
            phone: '+27829876543',
            address: '456 Oak Avenue',
            latitude: 0,
            longitude: 0,
            sectorId: 'sector-2',
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
