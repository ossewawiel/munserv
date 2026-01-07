/**
 * Color constants from material-theme.json
 * Generated via Material Theme Builder from brand colors
 */

// Core brand colors (seed colors)
export const coreColors = {
  primary: '#233D36',    // Forest Green
  secondary: '#D9613F',  // Terracotta
  tertiary: '#F1EDDA',   // Warm Beige
} as const;

// Light scheme colors
export const lightScheme = {
  primary: '#0C2721',
  onPrimary: '#FFFFFF',
  primaryContainer: '#233D36',
  onPrimaryContainer: '#8BA89E',
  // Berry-style light tints for UI backgrounds (visible but light)
  primaryLight: '#E8F0ED',     // Light forest green tint
  secondaryLight: '#FFEAE4',   // Light terracotta/peach tint (Berry-style visible)
  tertiaryLight: '#F7F5F0',    // Light cream tint for content background
  secondary: '#A2391A',
  onSecondary: '#FFFFFF',
  secondaryContainer: '#C35130',
  onSecondaryContainer: '#FFFBFF',
  tertiary: '#615F50',
  onTertiary: '#FFFFFF',
  tertiaryContainer: '#F1EDDA',
  onTertiaryContainer: '#6D6B5C',
  error: '#BA1A1A',
  onError: '#FFFFFF',
  errorContainer: '#FFDAD6',
  onErrorContainer: '#93000A',
  background: '#FAF9F7',
  onBackground: '#1A1C1B',
  surface: '#FAF9F7',
  onSurface: '#1A1C1B',
  surfaceVariant: '#DDE4E0',
  onSurfaceVariant: '#424846',
  outline: '#727975',
  outlineVariant: '#C1C8C4',
  shadow: '#000000',
  scrim: '#000000',
  inverseSurface: '#2F3130',
  inverseOnSurface: '#F1F1EF',
  inversePrimary: '#B0CDC3',
  surfaceDim: '#DADAD8',
  surfaceBright: '#FAF9F7',
  surfaceContainerLowest: '#FFFFFF',
  surfaceContainerLow: '#F4F3F2',
  surfaceContainer: '#EFEEEC',
  surfaceContainerHigh: '#E9E8E6',
  surfaceContainerHighest: '#E3E2E1',
} as const;

// Dark scheme colors
// Berry-inspired palette with forest green tint (matching brand #233D36)
// Pattern: Deep tinted background → progressively lighter tinted surfaces
export const darkScheme = {
  primary: '#B0CDC3',
  onPrimary: '#1B352E',
  primaryContainer: '#233D36',
  onPrimaryContainer: '#8BA89E',
  // Berry-style dark mode tints for UI backgrounds
  // These provide the visible distinction between header/sidebar/cards and content
  primaryLight: '#1E3830',     // Forest green tint for dark mode accents
  secondaryLight: '#3D2E2A',   // Terracotta tint for dark mode accents
  tertiaryLight: '#1A1F1D',    // Subtle warm tint for content background
  secondary: '#FFB5A0',
  onSecondary: '#601400',
  secondaryContainer: '#E76C49',
  onSecondaryContainer: '#400A00',
  tertiary: '#FFFFFF',
  onTertiary: '#323124',
  tertiaryContainer: '#E7E3D0',
  onTertiaryContainer: '#676556',
  error: '#FFB4AB',
  onError: '#690005',
  errorContainer: '#93000A',
  onErrorContainer: '#FFDAD6',
  // Main backgrounds - Berry-style deep tinted palette
  // darkPaper equivalent (deepest) - forest green tint
  background: '#0E1816',
  onBackground: '#D5E0DC',
  surface: '#0E1816',
  onSurface: '#D5E0DC',
  surfaceVariant: '#3A4742',
  onSurfaceVariant: '#BDC9C4',
  outline: '#87938E',
  outlineVariant: '#3A4742',
  shadow: '#000000',
  scrim: '#000000',
  inverseSurface: '#D5E0DC',
  inverseOnSurface: '#2A3532',
  inversePrimary: '#49645C',
  // Surface container hierarchy - progressively lighter with forest green tint
  // These create visible layers for cards, menus, headers (Berry pattern)
  // Berry reference: darkPaper #111936, darkLevel2 #212946 (difference ~16%)
  surfaceDim: '#0E1816',
  surfaceBright: '#3A4743',
  surfaceContainerLowest: '#091210',       // Darkest container
  surfaceContainerLow: '#141D1A',          // Slightly lighter
  surfaceContainer: '#1F2926',             // Cards, menus (darkLevel2 equivalent)
  surfaceContainerHigh: '#2A3633',         // Elevated cards, app bar
  surfaceContainerHighest: '#354240',      // Highest elevation surfaces
} as const;

// Issue state colors (consistent across light/dark)
export const issueStateColors = {
  reported: '#FF9800',    // Orange
  confirmed: '#2196F3',   // Blue
  in_progress: '#9C27B0', // Purple
  fixed: '#4CAF50',       // Green
  rejected: '#9E9E9E',    // Gray
  reopened: '#F44336',    // Red
} as const;

// Heat priority colors
export const heatColors = {
  minimal: '#9E9E9E',   // Gray
  low: '#4CAF50',       // Green
  medium: '#FF9800',    // Orange
  high: '#F44336',      // Red
  critical: '#9C27B0',  // Purple
} as const;

// Heat level type
export type HeatLevel = keyof typeof heatColors;

// Get heat level from numeric value
export function getHeatLevel(heat: number): HeatLevel {
  if (heat >= 80) return 'critical';
  if (heat >= 60) return 'high';
  if (heat >= 40) return 'medium';
  if (heat >= 20) return 'low';
  return 'minimal';
}
