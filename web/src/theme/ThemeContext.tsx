import {
  useState,
  useEffect,
  useMemo,
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
import { ThemeContext } from './ThemeContextValue';
import type { PodThemeConfig, ColorMode } from './types';

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
        const hostname = globalThis.location.hostname;
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
      } catch {
        // Fall back to default theme silently - error intentionally not logged to avoid noise
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
  const getSystemColorScheme = (): 'light' | 'dark' =>
    globalThis.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';

  const resolvedMode = colorMode === 'system' ? getSystemColorScheme() : colorMode;

  // Set the data-color-scheme attribute on the HTML element for CSS variable switching
  useEffect(() => {
    document.documentElement.dataset.colorScheme = resolvedMode;
  }, [resolvedMode]);

  // Listen for system color scheme changes when in 'system' mode
  useEffect(() => {
    if (colorMode !== 'system') return;

    const mediaQuery = globalThis.matchMedia('(prefers-color-scheme: dark)');
    const handleChange = (e: MediaQueryListEvent) => {
      document.documentElement.dataset.colorScheme = e.matches ? 'dark' : 'light';
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, [colorMode]);

  // Memoize context value to prevent unnecessary re-renders
  const contextValue = useMemo(
    () => ({ podConfig, colorMode, setColorMode, isLoading }),
    [podConfig, colorMode, isLoading]
  );

  return (
    <ThemeContext.Provider value={contextValue}>
      <MuiThemeProvider theme={theme} defaultMode={resolvedMode}>
        <CssBaseline />
        {children}
      </MuiThemeProvider>
    </ThemeContext.Provider>
  );
};
