import { describe, it, expect, vi, beforeEach, afterEach, beforeAll } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { ThemeProvider } from '@/theme';
import { CreatePodChiefPage } from './CreatePodChiefPage';

// Mock matchMedia for ThemeProvider
beforeAll(() => {
  Object.defineProperty(globalThis, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    })),
  });
});

// Mock the API
vi.mock('./api', () => ({
  bootstrapApi: {
    createPodChief: vi.fn(),
  },
}));

import { bootstrapApi } from './api';

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  resources: {
    en: {
      translation: {
        bootstrap: {
          createPodChief: 'Create Pod Chief',
          createPodChiefDescription: 'Create the first Pod Chief account for this pod.',
          displayName: 'Display Name',
          emailRequired: 'Email is required',
          emailInvalid: 'Invalid email format',
          displayNameRequired: 'Display name is required',
          createError: 'Failed to create Pod Chief',
          podChiefCreated: 'Pod Chief Created Successfully',
          temporaryPassword: 'Temporary Password',
          passwordNote: 'Save this password! It will only be shown once.',
          passwordCopied: 'Password copied to clipboard',
          emailSent: 'A welcome email has been sent to the Pod Chief.',
          goToLogin: 'Go to Admin Login',
          emailAlreadyExists: 'This email is already registered',
        },
        common: {
          loading: 'Loading...',
          appName: 'MunServ',
        },
        auth: {
          email: 'Email',
          welcomeBack: 'Welcome Back',
          enterCredentials: 'Enter your credentials',
        },
      },
    },
  },
});

function createQueryClient() {
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
  isSuperUser?: boolean;
  initialPath?: string;
}

function renderCreatePodChiefPage(options: RenderOptions = {}) {
  const { isSuperUser = true, initialPath = '/bootstrap/create-pod-chief' } = options;
  const queryClient = createQueryClient();

  // Set localStorage for super user check
  if (isSuperUser) {
    localStorage.setItem('isSuperUser', 'true');
  } else {
    localStorage.removeItem('isSuperUser');
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <I18nextProvider i18n={i18n}>
        <MemoryRouter initialEntries={[initialPath]}>
          <ThemeProvider>
            <Routes>
              <Route path="/bootstrap/create-pod-chief" element={<CreatePodChiefPage />} />
              <Route path="/login" element={<div data-testid="login-page">Login Page</div>} />
            </Routes>
          </ThemeProvider>
        </MemoryRouter>
      </I18nextProvider>
    </QueryClientProvider>
  );
}

describe('CreatePodChiefPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  afterEach(() => {
    localStorage.clear();
  });

  describe('access control', () => {
    it('should redirect to login if not super user', () => {
      renderCreatePodChiefPage({ isSuperUser: false });

      expect(screen.getByTestId('login-page')).toBeInTheDocument();
    });

    it('should render form if super user', () => {
      renderCreatePodChiefPage({ isSuperUser: true });

      expect(screen.getByRole('heading', { name: /create pod chief/i })).toBeInTheDocument();
      expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/display name/i)).toBeInTheDocument();
    });
  });

  describe('form rendering', () => {
    it('should render email field', () => {
      renderCreatePodChiefPage();

      expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    });

    it('should render display name field', () => {
      renderCreatePodChiefPage();

      expect(screen.getByLabelText(/display name/i)).toBeInTheDocument();
    });

    it('should render submit button', () => {
      renderCreatePodChiefPage();

      expect(screen.getByRole('button', { name: /create pod chief/i })).toBeInTheDocument();
    });
  });

  describe('validation', () => {
    it('should show error when email is empty', async () => {
      renderCreatePodChiefPage();

      const submitButton = screen.getByRole('button', { name: /create pod chief/i });
      await userEvent.click(submitButton);

      await waitFor(() => {
        expect(screen.getByText('Email is required')).toBeInTheDocument();
      });
    });

    it('should show error when email is invalid', async () => {
      renderCreatePodChiefPage();

      const emailField = screen.getByLabelText(/email/i);
      await userEvent.type(emailField, 'invalid-email');
      await userEvent.tab(); // Trigger blur

      await waitFor(() => {
        expect(screen.getByText('Invalid email format')).toBeInTheDocument();
      });
    });

    it('should show error when display name is empty', async () => {
      renderCreatePodChiefPage();

      const emailField = screen.getByLabelText(/email/i);
      await userEvent.type(emailField, 'valid@email.com');

      const submitButton = screen.getByRole('button', { name: /create pod chief/i });
      await userEvent.click(submitButton);

      await waitFor(() => {
        expect(screen.getByText('Display name is required')).toBeInTheDocument();
      });
    });

    it('should clear email error when user starts typing valid email', async () => {
      renderCreatePodChiefPage();

      const emailField = screen.getByLabelText(/email/i);
      await userEvent.type(emailField, 'invalid');
      await userEvent.tab();

      expect(screen.getByText('Invalid email format')).toBeInTheDocument();

      await userEvent.clear(emailField);
      await userEvent.type(emailField, 'valid@email.com');

      await waitFor(() => {
        expect(screen.queryByText('Invalid email format')).not.toBeInTheDocument();
      });
    });
  });

  describe('form submission', () => {
    it('should call API with correct data on valid submit', async () => {
      const mockResponse = {
        id: 'pod-chief-id',
        email: 'podchief@example.com',
        displayName: 'Pod Chief',
        role: 'pod_chief',
        temporaryPassword: 'TempPass123!',
        createdAt: '2026-01-26T10:00:00Z',
      };

      vi.mocked(bootstrapApi.createPodChief).mockResolvedValueOnce(mockResponse);

      renderCreatePodChiefPage();

      const emailField = screen.getByLabelText(/email/i);
      const displayNameField = screen.getByLabelText(/display name/i);
      const submitButton = screen.getByRole('button', { name: /create pod chief/i });

      await userEvent.type(emailField, 'podchief@example.com');
      await userEvent.type(displayNameField, 'Pod Chief');
      await userEvent.click(submitButton);

      await waitFor(() => {
        expect(bootstrapApi.createPodChief).toHaveBeenCalledWith({
          email: 'podchief@example.com',
          displayName: 'Pod Chief',
        });
      });
    });

    it('should show success dialog with temporary password after creation', async () => {
      const mockResponse = {
        id: 'pod-chief-id',
        email: 'podchief@example.com',
        displayName: 'Pod Chief',
        role: 'pod_chief',
        temporaryPassword: 'TempPass123!',
        createdAt: '2026-01-26T10:00:00Z',
      };

      vi.mocked(bootstrapApi.createPodChief).mockResolvedValueOnce(mockResponse);

      renderCreatePodChiefPage();

      const emailField = screen.getByLabelText(/email/i);
      const displayNameField = screen.getByLabelText(/display name/i);
      const submitButton = screen.getByRole('button', { name: /create pod chief/i });

      await userEvent.type(emailField, 'podchief@example.com');
      await userEvent.type(displayNameField, 'Pod Chief');
      await userEvent.click(submitButton);

      await waitFor(() => {
        expect(screen.getByText('Pod Chief Created Successfully')).toBeInTheDocument();
        expect(screen.getByDisplayValue('TempPass123!')).toBeInTheDocument();
        expect(screen.getByText(/save this password/i)).toBeInTheDocument();
      });
    });

    it('should show "Go to Admin Login" button in success dialog', async () => {
      const mockResponse = {
        id: 'pod-chief-id',
        email: 'podchief@example.com',
        displayName: 'Pod Chief',
        role: 'pod_chief',
        temporaryPassword: 'TempPass123!',
        createdAt: '2026-01-26T10:00:00Z',
      };

      vi.mocked(bootstrapApi.createPodChief).mockResolvedValueOnce(mockResponse);

      renderCreatePodChiefPage();

      await userEvent.type(screen.getByLabelText(/email/i), 'podchief@example.com');
      await userEvent.type(screen.getByLabelText(/display name/i), 'Pod Chief');
      await userEvent.click(screen.getByRole('button', { name: /create pod chief/i }));

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /go to admin login/i })).toBeInTheDocument();
      });
    });
  });

  describe('error handling', () => {
    it('should show error message when API returns 409 (email exists)', async () => {
      const error = {
        response: {
          status: 409,
          data: { code: 'email_exists' },
        },
      };

      vi.mocked(bootstrapApi.createPodChief).mockRejectedValueOnce(error);

      renderCreatePodChiefPage();

      await userEvent.type(screen.getByLabelText(/email/i), 'existing@example.com');
      await userEvent.type(screen.getByLabelText(/display name/i), 'Pod Chief');
      await userEvent.click(screen.getByRole('button', { name: /create pod chief/i }));

      await waitFor(() => {
        expect(screen.getByText('This email is already registered')).toBeInTheDocument();
      });
    });

    it('should show generic error for other API errors', async () => {
      const error = new Error('Network error');

      vi.mocked(bootstrapApi.createPodChief).mockRejectedValueOnce(error);

      renderCreatePodChiefPage();

      await userEvent.type(screen.getByLabelText(/email/i), 'podchief@example.com');
      await userEvent.type(screen.getByLabelText(/display name/i), 'Pod Chief');
      await userEvent.click(screen.getByRole('button', { name: /create pod chief/i }));

      await waitFor(() => {
        expect(screen.getByText('Failed to create Pod Chief')).toBeInTheDocument();
      });
    });

    it('should allow dismissing error alert', async () => {
      const error = new Error('Network error');

      vi.mocked(bootstrapApi.createPodChief).mockRejectedValueOnce(error);

      renderCreatePodChiefPage();

      await userEvent.type(screen.getByLabelText(/email/i), 'podchief@example.com');
      await userEvent.type(screen.getByLabelText(/display name/i), 'Pod Chief');
      await userEvent.click(screen.getByRole('button', { name: /create pod chief/i }));

      await waitFor(() => {
        expect(screen.getByText('Failed to create Pod Chief')).toBeInTheDocument();
      });

      // Close the alert
      const closeButton = screen.getByRole('button', { name: /close/i });
      await userEvent.click(closeButton);

      await waitFor(() => {
        expect(screen.queryByText('Failed to create Pod Chief')).not.toBeInTheDocument();
      });
    });
  });

  describe('loading state', () => {
    it('should disable fields during submission', async () => {
      // Make the API call hang
      vi.mocked(bootstrapApi.createPodChief).mockImplementation(
        () => new Promise(() => {}) // Never resolves
      );

      renderCreatePodChiefPage();

      await userEvent.type(screen.getByLabelText(/email/i), 'podchief@example.com');
      await userEvent.type(screen.getByLabelText(/display name/i), 'Pod Chief');
      await userEvent.click(screen.getByRole('button', { name: /create pod chief/i }));

      await waitFor(() => {
        expect(screen.getByLabelText(/email/i)).toBeDisabled();
        expect(screen.getByLabelText(/display name/i)).toBeDisabled();
      });
    });

    it('should show loading text in button during submission', async () => {
      vi.mocked(bootstrapApi.createPodChief).mockImplementation(
        () => new Promise(() => {})
      );

      renderCreatePodChiefPage();

      await userEvent.type(screen.getByLabelText(/email/i), 'podchief@example.com');
      await userEvent.type(screen.getByLabelText(/display name/i), 'Pod Chief');
      await userEvent.click(screen.getByRole('button', { name: /create pod chief/i }));

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /loading/i })).toBeInTheDocument();
      });
    });
  });

  describe('clipboard functionality', () => {
    it('should copy password to clipboard when copy button is clicked', async () => {
      const mockResponse = {
        id: 'pod-chief-id',
        email: 'podchief@example.com',
        displayName: 'Pod Chief',
        role: 'pod_chief',
        temporaryPassword: 'TempPass123!',
        createdAt: '2026-01-26T10:00:00Z',
      };

      vi.mocked(bootstrapApi.createPodChief).mockResolvedValueOnce(mockResponse);

      // Mock clipboard API
      const writeTextMock = vi.fn().mockResolvedValue(undefined);
      Object.assign(navigator, {
        clipboard: {
          writeText: writeTextMock,
        },
      });

      renderCreatePodChiefPage();

      await userEvent.type(screen.getByLabelText(/email/i), 'podchief@example.com');
      await userEvent.type(screen.getByLabelText(/display name/i), 'Pod Chief');
      await userEvent.click(screen.getByRole('button', { name: /create pod chief/i }));

      await waitFor(() => {
        expect(screen.getByText('Pod Chief Created Successfully')).toBeInTheDocument();
      });

      // Click copy button (the IconButton in the InputAdornment)
      const copyButtons = screen.getAllByRole('button');
      const copyButton = copyButtons.find(btn => btn.querySelector('svg'));
      if (copyButton) {
        await userEvent.click(copyButton);
      }

      await waitFor(() => {
        expect(writeTextMock).toHaveBeenCalledWith('TempPass123!');
        expect(screen.getByText('Password copied to clipboard')).toBeInTheDocument();
      });
    });
  });
});
