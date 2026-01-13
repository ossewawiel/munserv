import { createContext } from 'react';

import type { PodThemeConfig, ColorMode } from './types';

export interface ThemeContextValue {
  podConfig: PodThemeConfig;
  colorMode: ColorMode;
  setColorMode: (mode: ColorMode) => void;
  isLoading: boolean;
}

export const ThemeContext = createContext<ThemeContextValue | null>(null);
