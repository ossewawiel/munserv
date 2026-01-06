import {
  createContext,
  useContext,
  useState,
  useEffect,
  type FC,
  type ReactNode,
} from 'react';
import {
  ThemeProvider as MuiThemeProvider,
  type Theme,
} from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';

import { createPodTheme } from './createPodTheme';
import { defaultPodConfig } from './defaultTheme';
import type { PodThemeConfig, ColorMode } from './types';

interface ThemeContextValue {
  podConfig: PodThemeConfig;
  colorMode: ColorMode;
  setColorMode: (mode: ColorMode) => void;
  isLoading: boolean;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export const useThemeContext = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useThemeContext must be used within ThemeProvider');
  }
  return context;
};

interface ThemeProviderProps {
  children: ReactNode;
}

export const ThemeProvider: FC<ThemeProviderProps> = ({ children }) => {
  const [podConfig, setPodConfig] = useState<PodThemeConfig>(defaultPodConfig);
  const [colorMode, setColorMode] = useState<ColorMode>('system');
  const [isLoading, setIsLoading] = useState(true);
  const [theme, setTheme] = useState<Theme>(() => createPodTheme(defaultPodConfig));

  // Load pod theme config on mount
  useEffect(() => {
    const loadPodTheme = async () => {
      try {
        // Check for environment variable overrides first
        const envPrimary = import.meta.env.VITE_POD_PRIMARY_COLOR;
        const envSecondary = import.meta.env.VITE_POD_SECONDARY_COLOR;
        const envFont = import.meta.env.VITE_POD_FONT_FAMILY;

        if (envPrimary || envSecondary || envFont) {
          const config: PodThemeConfig = {
            ...defaultPodConfig,
            fonts: {
              ...defaultPodConfig.fonts,
              ...(envFont && { primary: envFont }),
            },
            colors: {
              ...defaultPodConfig.colors,
              ...(envPrimary && { primary: envPrimary }),
              ...(envSecondary && { secondary: envSecondary }),
            },
          };
          setPodConfig(config);
          setTheme(createPodTheme(config));
          setIsLoading(false);
          return;
        }

        // Try to load from API based on subdomain
        const hostname = window.location.hostname;
        // Skip API call for localhost
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
          setIsLoading(false);
          return;
        }

        const podId = hostname.split('.')[0];
        const response = await fetch(`/api/v1/pods/${podId}/theme`);

        if (response.ok) {
          const config: PodThemeConfig = await response.json();
          setPodConfig(config);
          setTheme(createPodTheme(config));
        }
      } catch (error) {
        // Fall back to default theme silently
        console.warn('Failed to load pod theme, using default');
      } finally {
        setIsLoading(false);
      }
    };

    loadPodTheme();
  }, []);

  // Load persisted color mode preference
  useEffect(() => {
    const stored = localStorage.getItem('munserv-color-mode') as ColorMode | null;
    if (stored && ['light', 'dark', 'system'].includes(stored)) {
      setColorMode(stored);
    }
  }, []);

  // Persist color mode preference
  useEffect(() => {
    localStorage.setItem('munserv-color-mode', colorMode);
  }, [colorMode]);

  // Determine the actual mode to use (resolve 'system' to light/dark)
  const resolvedMode = colorMode === 'system'
    ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    : colorMode;

  return (
    <ThemeContext.Provider value={{ podConfig, colorMode, setColorMode, isLoading }}>
      <MuiThemeProvider theme={theme} defaultMode={resolvedMode}>
        <CssBaseline />
        {children}
      </MuiThemeProvider>
    </ThemeContext.Provider>
  );
};
