import type { PodThemeConfig } from './types';

/**
 * Default pod theme configuration
 * Used when no pod-specific theme is loaded
 */
export const defaultPodConfig: PodThemeConfig = {
  podId: 'default',
  fonts: {
    primary: 'Source Sans 3',
    fallback: 'Roboto, Helvetica, Arial, sans-serif',
  },
  colors: {
    primary: '#233D36',   // Forest Green
    secondary: '#D9613F', // Terracotta
    tertiary: '#F1EDDA',  // Warm Beige
  },
};
