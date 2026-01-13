import { useContext } from 'react';

import { ThemeContext } from './ThemeContextValue';

/**
 * Hook to access theme context values.
 * Must be used within a ThemeProvider.
 */
export const useThemeContext = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useThemeContext must be used within ThemeProvider');
  }
  return context;
};
