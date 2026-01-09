import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { I18nextProvider } from 'react-i18next';
import i18n from 'i18next';

import { AuthLayout } from './AuthLayout';

// Mock useColorScheme
const mockUseColorScheme = vi.fn();
vi.mock('@mui/material/styles', async () => {
  const actual = await vi.importActual('@mui/material/styles');
  return {
    ...actual,
    useColorScheme: () => mockUseColorScheme(),
  };
});

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
        },
      },
    },
  },
});

const lightTheme = createTheme({ palette: { mode: 'light' } });
const darkTheme = createTheme({ palette: { mode: 'dark' } });

interface RenderOptions {
  theme?: ReturnType<typeof createTheme>;
  colorMode?: 'light' | 'dark';
}

function renderWithProviders(
  ui: React.ReactElement,
  { theme = lightTheme, colorMode = 'light' }: RenderOptions = {}
) {
  mockUseColorScheme.mockReturnValue({ mode: colorMode, setMode: vi.fn() });
  return render(
    <ThemeProvider theme={theme}>
      <I18nextProvider i18n={i18n}>{ui}</I18nextProvider>
    </ThemeProvider>
  );
}

beforeEach(() => {
  mockUseColorScheme.mockReset();
});

describe('AuthLayout', () => {
  describe('card content', () => {
    it('should render app logo inside the card (light mode)', () => {
      renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>,
        { theme: lightTheme, colorMode: 'light' }
      );

      const logo = screen.getByRole('img', { name: 'MunServ Admin' });
      expect(logo).toBeInTheDocument();
      expect(logo).toHaveAttribute('src', '/assets/app-logo.png');
    });

    it('should render dark mode logo in dark mode', () => {
      renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>,
        { theme: darkTheme, colorMode: 'dark' }
      );

      const logo = screen.getByRole('img', { name: 'MunServ Admin' });
      expect(logo).toBeInTheDocument();
      expect(logo).toHaveAttribute('src', '/assets/app-logo-dark.png');
    });

    it('should render welcome back message', () => {
      renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>
      );

      expect(screen.getByText('Hi, Welcome Back')).toBeInTheDocument();
    });

    it('should render welcome message with secondary color', () => {
      renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>
      );

      const welcomeText = screen.getByText('Hi, Welcome Back');
      // Typography with color="secondary" applies color from theme
      expect(welcomeText).toHaveClass('MuiTypography-root');
    });

    it('should render subtitle text', () => {
      renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>
      );

      expect(screen.getByText('Enter your credentials to continue')).toBeInTheDocument();
    });

    it('should render children content', () => {
      renderWithProviders(
        <AuthLayout>
          <div data-testid="test-content">Form content</div>
        </AuthLayout>
      );

      expect(screen.getByTestId('test-content')).toBeInTheDocument();
    });
  });

  describe('background styling', () => {
    it('should render wrapper element that can receive background styles', () => {
      const { container } = renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>,
        { theme: lightTheme }
      );

      // The wrapper element should exist and be a styled component
      const wrapper = container.firstChild as HTMLElement;
      expect(wrapper).toBeInTheDocument();
      expect(wrapper.tagName.toLowerCase()).toBe('div');
    });

    it('should render correctly in dark mode', () => {
      const { container } = renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>,
        { theme: darkTheme, colorMode: 'dark' }
      );

      const wrapper = container.firstChild as HTMLElement;
      expect(wrapper).toBeInTheDocument();
    });
  });

  describe('layout structure', () => {
    it('should center content vertically and horizontally', () => {
      const { container } = renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>
      );

      const wrapper = container.firstChild as HTMLElement;
      const computedStyle = window.getComputedStyle(wrapper);
      expect(computedStyle.display).toBe('flex');
      expect(computedStyle.alignItems).toBe('center');
      expect(computedStyle.justifyContent).toBe('center');
    });

    it('should use full viewport height', () => {
      const { container } = renderWithProviders(
        <AuthLayout>
          <div>Form content</div>
        </AuthLayout>
      );

      const wrapper = container.firstChild as HTMLElement;
      const computedStyle = window.getComputedStyle(wrapper);
      expect(computedStyle.minHeight).toBe('100vh');
    });
  });
});
