/**
 * Pod-specific theme configuration
 * Each pod can customize these values for their branding
 */
export interface PodThemeConfig {
  podId: string;
  fonts: {
    primary: string;        // e.g., "Source Sans 3"
    fallback?: string;      // e.g., "sans-serif"
  };
  colors: {
    primary: string;        // e.g., "#233D36"
    secondary: string;      // e.g., "#D9613F"
    tertiary?: string;      // e.g., "#F1EDDA"
  };
  logo?: string;            // URL to pod logo
}

/**
 * Color mode preference
 */
export type ColorMode = 'light' | 'dark' | 'system';

/**
 * Issue state for coloring badges
 */
export type IssueState =
  | 'reported'
  | 'confirmed'
  | 'in_progress'
  | 'fixed'
  | 'rejected'
  | 'reopened';

/**
 * Heat level for priority indicators
 */
export type HeatLevel = 'low' | 'medium' | 'high' | 'critical';
