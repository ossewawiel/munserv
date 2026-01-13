// Theme exports
export { createPodTheme } from './createPodTheme';
export { defaultPodConfig } from './defaultTheme';
export { ThemeProvider } from './ThemeContext';
export { useThemeContext } from './useThemeContext';
export {
  coreColors,
  lightScheme,
  darkScheme,
  issueStateColors,
  heatColors,
  getHeatLevel,
} from './colors';
export type { PodThemeConfig, ColorMode, IssueState, HeatLevel } from './types';

// Berry-inspired constants
export {
  gridSpacing,
  avatarSizes,
  type AvatarSize,
  drawerWidth,
  drawerWidthMini,
  headerHeight,
  commonAvatar,
  mediumAvatar,
} from './constants';
export {
  cardHoverShadow,
  cardHoverShadowDark,
  colorShadows,
  colorShadowsDark,
  type ColorShadowKey,
} from './shadows';
