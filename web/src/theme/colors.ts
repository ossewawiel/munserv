/**
 * Colour constants. Values are generated from design/tokens into ./generated/tokens.ts;
 * this module keeps the names the rest of the app uses and the helpers built on them.
 */
import {
  brand,
  schemeLight,
  schemeDark,
  semanticIssueState,
  semanticIssueType,
  semanticHeat,
} from './generated/tokens';

// Core brand colors (seed colors)
export const coreColors = brand;

// Light scheme colors
export const lightScheme = schemeLight;

// Dark scheme colors
export const darkScheme = schemeDark;

// Issue state colors (consistent across light/dark)
export const issueStateColors = semanticIssueState;

// Heat priority colors
export const heatColors = {
  minimal: semanticHeat.minimal,
  low: semanticHeat.low,
  medium: semanticHeat.medium,
  high: semanticHeat.high,
  critical: semanticHeat.critical,
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

// Issue type colors for map pins and filter buttons
export const issueTypeColors = semanticIssueType;

export type IssueTypeColor = keyof typeof issueTypeColors;
