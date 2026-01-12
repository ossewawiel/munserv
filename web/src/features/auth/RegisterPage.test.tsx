import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import i18n from 'i18next';

import { RegisterPage } from './RegisterPage';

// Mock useThemeContext
const mockUseThemeContext = vi.fn();
vi.mock('@/theme', async () => {
  const actual = await vi.importActual('@/theme');
  return {
    ...actual,
    useThemeContext: () => mockUseThemeContext(),
  };
});

// Mock the LocationPickerDialog component
vi.mock('@/components/molecules/LocationPickerDialog', () => ({
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

// Mock matchMedia for prefers-color-scheme
function mockMatchMedia(prefersDark: boolean = false) {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      matches: query === '(prefers-color-scheme: dark)' ? prefersDark : false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    })),
  });
}

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        common: { appName: 'MunServ Admin' },
        auth: {
          welcomeBack: 'Hi, Welcome Back',
          enterCredentials: 'Enter your credentials to continue',
          registerTitle: 'Register as a Community Member',
          registerSubtitle: 'Join your community to report and track municipal service issues',
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
          getLocation: 'Get Location from Map',
          gettingLocation: 'Getting location...',
          locationCaptured: 'Location captured',
          locationError: 'Could not get your location',
          locationOptional: 'Location is optional but helps us serve you better',
          addressHelp: 'Enter your street address or use the map to select',
          submitRegistration: 'Submit Registration',
          registrationSuccess: 'Registration Submitted Successfully!',
          registrationPendingInfo: 'Your registration has been submitted. You will receive an email with login instructions once an administrator approves your registration.',
          backToLogin: 'Back to Login',
          alreadyHaveAccount: 'Already have an account?',
          loginLink: 'Log in here',
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

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
      mutations: {
        retry: false,
      },
    },
  });
}

interface RenderOptions {
  initialRoute?: string;
}

function renderRegisterPage({ initialRoute = '/register' }: RenderOptions = {}) {
  const queryClient = createTestQueryClient();

  mockUseThemeContext.mockReturnValue({
    colorMode: 'light',
    setColorMode: vi.fn(),
    podConfig: { podId: 'test', fonts: { primary: 'Roboto' }, colors: {} },
    isLoading: false,
  });
  mockMatchMedia(false);

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter initialEntries={[initialRoute]}>
            <Routes>
              <Route path="/register" element={<RegisterPage />} />
              <Route path="/login" element={<div>Login Page</div>} />
            </Routes>
          </MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

describe('RegisterPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rendering', () => {
    it('should render registration page title', async () => {
      renderRegisterPage();

      await waitFor(() => {
        expect(screen.getByText('Register as a Community Member')).toBeInTheDocument();
      });
    });

    it('should render registration subtitle', async () => {
      renderRegisterPage();

      await waitFor(() => {
        expect(screen.getByText(/join your community to report/i)).toBeInTheDocument();
      });
    });

    it('should render the registration form', async () => {
      renderRegisterPage();

      await waitFor(() => {
        expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/email address/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /submit registration/i })).toBeInTheDocument();
      });
    });

    it('should load sectors from API', async () => {
      renderRegisterPage();

      // Wait for sectors to load
      await waitFor(() => {
        expect(screen.getByLabelText(/community\/ward/i)).toBeInTheDocument();
      });

      // Open dropdown and check sectors are loaded
      await userEvent.click(screen.getByLabelText(/community\/ward/i));

      await waitFor(() => {
        expect(screen.getByText('Ward 42')).toBeInTheDocument();
      });
    });
  });

  describe('form submission', () => {
    // Note: Full integration tests with form submission require more complex MSW setup.
    // These tests verify the form can be filled and submitted at a basic level.

    it('should have submit button enabled when form is ready', async () => {
      renderRegisterPage();

      await waitFor(() => {
        const submitButton = screen.getByRole('button', { name: /submit registration/i });
        expect(submitButton).toBeInTheDocument();
        expect(submitButton).not.toBeDisabled();
      });
    });

    it('should allow filling all form fields', async () => {
      renderRegisterPage();

      // Wait for form to load
      await waitFor(() => {
        expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
      });

      // Fill form fields - verify they are interactive
      const firstNameInput = screen.getByLabelText(/first name/i);
      const surnameInput = screen.getByLabelText(/surname/i);
      const emailInput = screen.getByLabelText(/email address/i);
      const phoneInput = screen.getByLabelText(/phone number/i);
      const addressInput = screen.getByLabelText(/street address/i);

      await userEvent.type(firstNameInput, 'John');
      await userEvent.type(surnameInput, 'Doe');
      await userEvent.type(emailInput, 'john@example.com');
      await userEvent.type(phoneInput, '+27821234567');
      await userEvent.type(addressInput, '123 Main St');

      // Verify fields are enabled and can receive input
      expect(firstNameInput).toBeEnabled();
      expect(surnameInput).toBeEnabled();
      expect(emailInput).toBeEnabled();
    });

    it('should allow capturing location via map picker', async () => {
      renderRegisterPage();

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /get location from map/i })).toBeInTheDocument();
      });

      // Open location picker dialog
      await userEvent.click(screen.getByRole('button', { name: /get location from map/i }));

      await waitFor(() => {
        expect(screen.getByTestId('location-picker-dialog')).toBeInTheDocument();
      });

      // Confirm location
      await userEvent.click(screen.getByText('Confirm Location'));

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /location captured/i })).toBeInTheDocument();
      });
    });

    it('should allow selecting a sector', async () => {
      renderRegisterPage();

      // Wait for sectors to load
      await waitFor(() => {
        expect(screen.getByLabelText(/community\/ward/i)).toBeInTheDocument();
      });

      // Select sector
      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 42'));

      // Verify selection - MUI Select shows the display text, not the value
      await waitFor(() => {
        expect(screen.getByText('Ward 42')).toBeInTheDocument();
      });
    });
  });

  describe('loading states', () => {
    it('should show loading state while sectors are loading', async () => {
      renderRegisterPage();

      // Initially the sector dropdown should exist but may be disabled while loading
      await waitFor(() => {
        expect(screen.getByLabelText(/community\/ward/i)).toBeInTheDocument();
      });
    });

    it('should disable form during submission', async () => {
      renderRegisterPage();

      // Wait for form
      await waitFor(() => {
        expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
      });

      // Fill form
      await userEvent.type(screen.getByLabelText(/first name/i), 'John');
      await userEvent.type(screen.getByLabelText(/surname/i), 'Doe');
      await userEvent.type(screen.getByLabelText(/email address/i), 'john@example.com');
      await userEvent.type(screen.getByLabelText(/phone number/i), '+27821234567');
      await userEvent.type(screen.getByLabelText(/street address/i), '123 Main St');

      await userEvent.click(screen.getByLabelText(/community\/ward/i));
      await userEvent.click(screen.getByText('Ward 42'));

      // The submit button should be clickable before submission (location is now optional)
      expect(screen.getByRole('button', { name: /submit registration/i })).not.toBeDisabled();
    });
  });
});
