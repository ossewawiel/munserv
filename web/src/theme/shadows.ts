/**
 * Berry-inspired shadow definitions
 * Uses MunServ color palette for color-matched shadows
 */

/**
 * Card hover shadow (Berry pattern)
 * Applied on card hover for subtle elevation effect
 */
export const cardHoverShadow = '0 2px 14px 0 rgb(32 40 45 / 8%)';

/**
 * Card hover shadow for dark mode
 */
export const cardHoverShadowDark = '0 2px 14px 0 rgb(0 0 0 / 20%)';

/**
 * Color-matched shadows using MunServ palette
 * These create colored glow effects matching the component's semantic color
 */
export const colorShadows = {
  primary: '0 4px 20px 0 rgba(35, 61, 54, 0.14)',     // Forest Green shadow
  secondary: '0 4px 20px 0 rgba(217, 97, 63, 0.14)', // Terracotta shadow
  success: '0 4px 20px 0 rgba(76, 175, 80, 0.14)',
  warning: '0 4px 20px 0 rgba(255, 152, 0, 0.14)',
  error: '0 4px 20px 0 rgba(244, 67, 54, 0.14)',
  info: '0 4px 20px 0 rgba(33, 150, 243, 0.14)',
} as const;

/**
 * Dark mode color shadow variants
 * Slightly more visible against dark backgrounds
 */
export const colorShadowsDark = {
  primary: '0 4px 20px 0 rgba(176, 205, 195, 0.14)',
  secondary: '0 4px 20px 0 rgba(255, 181, 160, 0.14)',
  success: '0 4px 20px 0 rgba(129, 199, 132, 0.14)',
  warning: '0 4px 20px 0 rgba(255, 183, 77, 0.14)',
  error: '0 4px 20px 0 rgba(255, 180, 171, 0.14)',
  info: '0 4px 20px 0 rgba(100, 181, 246, 0.14)',
} as const;

export type ColorShadowKey = keyof typeof colorShadows;
