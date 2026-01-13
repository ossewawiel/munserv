import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { ProfileMenu } from './ProfileMenu';

// Mock useThemeContext
const mockSetColorMode = vi.fn();
vi.mock('@/theme', async () => {
  const actual = await vi.importActual('@/theme');
  return {
    ...actual,
    useThemeContext: () => ({
      colorMode: 'light' as const,
      setColorMode: mockSetColorMode,
      podConfig: { podId: 'test', fonts: { primary: 'Roboto' }, colors: {} },
      isLoading: false,
    }),
    commonAvatar: {},
    mediumAvatar: {},
  };
});

vi.mock('@/theme/ThemeContext', async () => {
  const actual = await vi.importActual('@/theme/ThemeContext');
  return {
    ...actual,
    useThemeContext: () => ({
      colorMode: 'light' as const,
      setColorMode: mockSetColorMode,
      podConfig: { podId: 'test', fonts: { primary: 'Roboto' }, colors: {} },
      isLoading: false,
    }),
  };
});

// Mock useLogout
const mockLogoutMutate = vi.fn();
vi.mock('@/features/auth/hooks', () => ({
  useLogout: () => ({
    mutate: mockLogoutMutate,
    isPending: false,
  }),
}));

// Mock i18n
vi.mock('@/lib/i18n', () => ({
  SUPPORTED_LANGUAGES: ['en', 'af', 'zu'] as const,
  LANGUAGE_NAMES: { en: 'English', af: 'Afrikaans', zu: 'isiZulu' },
  LANGUAGE_NATIVE_NAMES: { en: 'English', af: 'Afrikaans', zu: 'isiZulu' },
}));

// Initialize i18next for tests
i18n.init({
  lng: 'en',
  fallbackLng: 'en',
  resources: {
    en: {
      translation: {
        profile: {
          menuTrigger: 'Profile menu',
          greeting: {
            morning: 'Good morning',
            afternoon: 'Good afternoon',
            evening: 'Good evening',
          },
          mood: 'Mood',
          moodLight: 'Light',
          moodDark: 'Dark',
          moodSystem: 'System',
          language: 'Language',
          selectLanguage: 'Select preferred language',
        },
        auth: {
          logout: 'Logout',
        },
        common: {
          loading: 'Loading...',
        },
      },
    },
    af: {
      translation: {
        profile: {
          menuTrigger: 'Profielmenu',
          greeting: {
            morning: 'Goeie môre',
            afternoon: 'Goeie middag',
            evening: 'Goeie aand',
          },
          mood: 'Modus',
          moodLight: 'Lig',
          moodDark: 'Donker',
          moodSystem: 'Stelsel',
          language: 'Taal',
          selectLanguage: 'Kies voorkeur taal',
        },
        auth: {
          logout: 'Teken uit',
        },
        common: {
          loading: 'Laai...',
        },
      },
    },
    zu: {
      translation: {
        profile: {
          menuTrigger: 'Imenyu yephrofayili',
          greeting: {
            morning: 'Sawubona ekuseni',
            afternoon: 'Sawubona emini',
            evening: 'Sawubona ebusuku',
          },
          mood: 'Imodi',
          moodLight: 'Ukukhanya',
          moodDark: 'Ubumnyama',
          moodSystem: 'Isistimu',
          language: 'Ulimi',
          selectLanguage: 'Khetha ulimi oluncamelayo',
        },
        auth: {
          logout: 'Phuma',
        },
        common: {
          loading: 'Iyalayisha...',
        },
      },
    },
  },
});

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: { main: '#0C2721' },
  },
});

// Mock localStorage for admin data
const mockAdmin = {
  id: 'admin-1',
  name: 'John Doe',
  email: 'john@example.com',
};

function mockMatchMedia() {
  Object.defineProperty(window, 'matchMedia', {
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
}

function renderWithProviders(ui: React.ReactElement) {
  mockMatchMedia();

  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <I18nextProvider i18n={i18n}>
          <MemoryRouter>{ui}</MemoryRouter>
        </I18nextProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

beforeEach(() => {
  vi.clearAllMocks();
  // Set up localStorage with admin data
  localStorage.setItem('admin', JSON.stringify(mockAdmin));
  // Reset language to English for each test
  i18n.changeLanguage('en');
});

afterEach(() => {
  localStorage.clear();
});

describe('ProfileMenu', () => {
  describe('trigger button', () => {
    it('should render profile trigger button', () => {
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      expect(trigger).toBeInTheDocument();
    });

    it('should open menu when trigger is clicked', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      // Menu should be open and show greeting
      await waitFor(() => {
        expect(screen.getByText(/good (morning|afternoon|evening)/i)).toBeInTheDocument();
      });
    });
  });

  describe('greeting', () => {
    it('should display greeting with user name', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      await waitFor(() => {
        expect(screen.getByText('John Doe')).toBeInTheDocument();
      });
    });
  });

  describe('mood (theme) toggle', () => {
    it('should display mood section with current mode', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      await waitFor(() => {
        expect(screen.getByText(/mood/i)).toBeInTheDocument();
      });
    });

    it('should change to dark mode when dark is selected', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /dark/i })).toBeInTheDocument();
      });

      const darkOption = screen.getByRole('button', { name: /dark/i });
      await user.click(darkOption);

      expect(mockSetColorMode).toHaveBeenCalledWith('dark');
    });
  });

  describe('language selection', () => {
    it('should display language section with current language name', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      await waitFor(() => {
        expect(screen.getByText(/language/i)).toBeInTheDocument();
        // Current language name should be displayed
        expect(screen.getByText('English')).toBeInTheDocument();
      });
    });

    it('should open language dropdown when language button is clicked', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      // Click the language selector button
      const languageButton = await screen.findByRole('button', { name: /select preferred language/i });
      await user.click(languageButton);

      // Language options should appear
      await waitFor(() => {
        expect(screen.getByText(/\(English\)/)).toBeInTheDocument();
        expect(screen.getByText(/\(Afrikaans\)/)).toBeInTheDocument();
        expect(screen.getByText(/\(isiZulu\)/)).toBeInTheDocument();
      });
    });

    it('should change language when Afrikaans is selected from dropdown', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      // Click the language selector button
      const languageButton = await screen.findByRole('button', { name: /select preferred language/i });
      await user.click(languageButton);

      // Click Afrikaans option
      await waitFor(() => {
        expect(screen.getByText(/\(Afrikaans\)/)).toBeInTheDocument();
      });
      const afOption = screen.getByText(/\(Afrikaans\)/).closest('div[role="button"]');
      await user.click(afOption!);

      // After clicking, language should change to Afrikaans
      expect(i18n.language).toBe('af');
    });

    it('should change language when Zulu is selected from dropdown', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      // Click the language selector button
      const languageButton = await screen.findByRole('button', { name: /select preferred language/i });
      await user.click(languageButton);

      // Click Zulu option
      await waitFor(() => {
        expect(screen.getByText(/\(isiZulu\)/)).toBeInTheDocument();
      });
      const zuOption = screen.getByText(/\(isiZulu\)/).closest('div[role="button"]');
      await user.click(zuOption!);

      // After clicking, language should change to Zulu
      expect(i18n.language).toBe('zu');
    });
  });

  describe('logout', () => {
    it('should display logout option', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /logout/i })).toBeInTheDocument();
      });
    });

    it('should call logout when logout is clicked', async () => {
      const user = userEvent.setup();
      renderWithProviders(<ProfileMenu />);

      const trigger = screen.getByRole('button', { name: /profile/i });
      await user.click(trigger);

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /logout/i })).toBeInTheDocument();
      });

      const logoutButton = screen.getByRole('button', { name: /logout/i });
      await user.click(logoutButton);

      expect(mockLogoutMutate).toHaveBeenCalled();
    });
  });
});
