import { createTheme, type ThemeOptions } from '@mui/material/styles';
import type { PodThemeConfig } from './types';
import { lightScheme, darkScheme } from './colors';

/**
 * Creates an MUI theme from pod configuration
 * Uses CSS variables for runtime access and color scheme support
 */
export function createPodTheme(config: PodThemeConfig) {
  const { fonts } = config;

  const themeOptions: ThemeOptions = {
    cssVariables: {
      cssVarPrefix: 'munserv',
      colorSchemeSelector: 'data-color-scheme',
    },
    colorSchemes: {
      light: {
        palette: {
          primary: {
            main: lightScheme.primary,
            contrastText: lightScheme.onPrimary,
            light: lightScheme.primaryContainer,
            dark: lightScheme.primary,
          },
          secondary: {
            main: lightScheme.secondary,
            contrastText: lightScheme.onSecondary,
            light: lightScheme.secondaryContainer,
            dark: lightScheme.secondary,
          },
          error: {
            main: lightScheme.error,
            contrastText: lightScheme.onError,
            light: lightScheme.errorContainer,
          },
          warning: {
            main: '#FF9800',
            contrastText: '#FFFFFF',
          },
          info: {
            main: '#2196F3',
            contrastText: '#FFFFFF',
          },
          success: {
            main: '#4CAF50',
            contrastText: '#FFFFFF',
          },
          background: {
            default: lightScheme.background,
            paper: lightScheme.surface,
          },
          text: {
            primary: lightScheme.onSurface,
            secondary: lightScheme.onSurfaceVariant,
          },
          divider: lightScheme.outlineVariant,
          action: {
            hover: lightScheme.surfaceContainerHigh,
            selected: lightScheme.surfaceContainerHighest,
          },
        },
      },
      dark: {
        palette: {
          primary: {
            main: darkScheme.primary,
            contrastText: darkScheme.onPrimary,
            light: darkScheme.primaryContainer,
            dark: darkScheme.primary,
          },
          secondary: {
            main: darkScheme.secondary,
            contrastText: darkScheme.onSecondary,
            light: darkScheme.secondaryContainer,
            dark: darkScheme.secondary,
          },
          error: {
            main: darkScheme.error,
            contrastText: darkScheme.onError,
            light: darkScheme.errorContainer,
          },
          warning: {
            main: '#FFB74D',
            contrastText: '#000000',
          },
          info: {
            main: '#64B5F6',
            contrastText: '#000000',
          },
          success: {
            main: '#81C784',
            contrastText: '#000000',
          },
          background: {
            default: darkScheme.background,
            paper: darkScheme.surfaceContainer,
          },
          text: {
            primary: darkScheme.onSurface,
            secondary: darkScheme.onSurfaceVariant,
          },
          divider: darkScheme.outlineVariant,
          action: {
            hover: darkScheme.surfaceContainerHigh,
            selected: darkScheme.surfaceContainerHighest,
          },
        },
      },
    },
    typography: {
      fontFamily: `"${fonts.primary}", ${fonts.fallback || 'sans-serif'}`,
      h1: { fontWeight: 300, letterSpacing: '-1.5px' },
      h2: { fontWeight: 300, letterSpacing: '-0.5px' },
      h3: { fontWeight: 400 },
      h4: { fontWeight: 400, letterSpacing: '0.25px' },
      h5: { fontWeight: 500 },
      h6: { fontWeight: 500, letterSpacing: '0.15px' },
      subtitle1: { fontWeight: 400, letterSpacing: '0.15px' },
      subtitle2: { fontWeight: 500, letterSpacing: '0.1px' },
      body1: { fontWeight: 400, letterSpacing: '0.5px' },
      body2: { fontWeight: 400, letterSpacing: '0.25px' },
      button: { fontWeight: 500, letterSpacing: '0.4px', textTransform: 'none' as const },
      caption: { fontWeight: 400, letterSpacing: '0.4px' },
      overline: { fontWeight: 400, letterSpacing: '1.5px' },
    },
    shape: {
      borderRadius: 8,
    },
    components: {
      MuiButton: {
        defaultProps: {
          disableElevation: true,
        },
        styleOverrides: {
          root: {
            textTransform: 'none',
            fontWeight: 500,
            borderRadius: 8,
          },
          sizeLarge: {
            padding: '12px 24px',
          },
          sizeMedium: {
            padding: '8px 16px',
          },
          sizeSmall: {
            padding: '4px 12px',
          },
        },
      },
      MuiTextField: {
        defaultProps: {
          variant: 'outlined',
          size: 'small',
        },
      },
      MuiSelect: {
        defaultProps: {
          variant: 'outlined',
          size: 'small',
        },
      },
      MuiCard: {
        defaultProps: {
          variant: 'outlined',
        },
        styleOverrides: {
          root: {
            borderRadius: 12,
          },
        },
      },
      MuiChip: {
        styleOverrides: {
          root: {
            fontWeight: 500,
            borderRadius: 8,
          },
        },
      },
      MuiDialog: {
        styleOverrides: {
          paper: {
            borderRadius: 28,
          },
        },
      },
      MuiPaper: {
        styleOverrides: {
          rounded: {
            borderRadius: 12,
          },
        },
      },
      MuiTableCell: {
        styleOverrides: {
          head: {
            fontWeight: 600,
          },
        },
      },
      MuiAppBar: {
        defaultProps: {
          elevation: 1,
          color: 'inherit',
        },
        styleOverrides: {
          root: {
            backgroundImage: 'none',
          },
        },
      },
      MuiCssBaseline: {
        styleOverrides: {
          body: {
            margin: 0,
            minHeight: '100vh',
          },
          '#root': {
            minHeight: '100vh',
          },
        },
      },
    },
  };

  return createTheme(themeOptions);
}
