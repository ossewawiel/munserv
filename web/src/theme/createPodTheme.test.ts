import { describe, it, expect } from 'vitest';
import { createPodTheme } from './createPodTheme';
import { defaultPodConfig } from './defaultTheme';
import { darkScheme, lightScheme } from './colors';

describe('createPodTheme', () => {
  describe('dark mode input autofill styling', () => {
    it('should have MuiOutlinedInput component overrides', () => {
      const theme = createPodTheme(defaultPodConfig);

      expect(theme.components?.MuiOutlinedInput).toBeDefined();
      expect(theme.components?.MuiOutlinedInput?.styleOverrides).toBeDefined();
    });

    it('should override webkit-autofill background in dark mode', () => {
      const theme = createPodTheme(defaultPodConfig);
      const styleOverrides = theme.components?.MuiOutlinedInput?.styleOverrides;

      // The input styleOverrides should include autofill styling
      expect(styleOverrides?.input).toBeDefined();

      // Type assertion for the complex style object
      const inputStyles = styleOverrides?.input as Record<string, unknown>;

      // Check that webkit-autofill is addressed in dark color scheme
      // MUI uses '[data-color-scheme="dark"] &' selector for dark mode CSS variable themes
      const darkSelector = Object.keys(inputStyles).find(
        (key) => key.includes('data-color-scheme') && key.includes('dark')
      );

      expect(darkSelector).toBeDefined();
    });

    it('should use theme-appropriate background color for dark mode autofill', () => {
      const theme = createPodTheme(defaultPodConfig);
      const styleOverrides = theme.components?.MuiOutlinedInput?.styleOverrides;
      const inputStyles = styleOverrides?.input as Record<string, unknown>;

      // Find the dark mode autofill selector
      const darkAutofillSelector = Object.keys(inputStyles).find(
        (key) =>
          key.includes('data-color-scheme') &&
          key.includes('dark') &&
          key.includes('autofill')
      );

      expect(darkAutofillSelector).toBeDefined();

      if (darkAutofillSelector) {
        const darkAutofillStyles = inputStyles[darkAutofillSelector] as Record<
          string,
          unknown
        >;
        // Should use a forest green tinted background, not blue
        // The background should reference surfaceContainerLow or similar dark scheme color
        const boxShadow = darkAutofillStyles?.WebkitBoxShadow as string;

        // Autofill override uses box-shadow inset to override browser color
        expect(boxShadow).toBeDefined();
        expect(boxShadow).toContain('inset');
        // Should contain a dark forest green color, not the default blue
        expect(boxShadow).toContain(darkScheme.surfaceContainerLow);
      }
    });

    it('should set appropriate text color for dark mode autofill', () => {
      const theme = createPodTheme(defaultPodConfig);
      const styleOverrides = theme.components?.MuiOutlinedInput?.styleOverrides;
      const inputStyles = styleOverrides?.input as Record<string, unknown>;

      // Find the dark mode autofill selector
      const darkAutofillSelector = Object.keys(inputStyles).find(
        (key) =>
          key.includes('data-color-scheme') &&
          key.includes('dark') &&
          key.includes('autofill')
      );

      if (darkAutofillSelector) {
        const darkAutofillStyles = inputStyles[darkAutofillSelector] as Record<
          string,
          unknown
        >;
        const textFillColor = darkAutofillStyles?.WebkitTextFillColor as string;

        // Text should be light colored for dark mode
        expect(textFillColor).toBeDefined();
        expect(textFillColor).toContain(darkScheme.onSurface);
      }
    });
  });

  describe('light mode input autofill styling', () => {
    it('should have appropriate light mode autofill styling', () => {
      const theme = createPodTheme(defaultPodConfig);
      const styleOverrides = theme.components?.MuiOutlinedInput?.styleOverrides;
      const inputStyles = styleOverrides?.input as Record<string, unknown>;

      // Light mode autofill should also be styled
      const lightAutofillSelector = Object.keys(inputStyles).find(
        (key) =>
          key.includes('data-color-scheme') &&
          key.includes('light') &&
          key.includes('autofill')
      );

      expect(lightAutofillSelector).toBeDefined();
    });

    it('should use cream background color for light mode autofill', () => {
      const theme = createPodTheme(defaultPodConfig);
      const styleOverrides = theme.components?.MuiOutlinedInput?.styleOverrides;
      const inputStyles = styleOverrides?.input as Record<string, unknown>;

      // Find the light mode autofill selector
      const lightAutofillSelector = Object.keys(inputStyles).find(
        (key) =>
          key.includes('data-color-scheme') &&
          key.includes('light') &&
          key.includes('autofill')
      );

      expect(lightAutofillSelector).toBeDefined();

      if (lightAutofillSelector) {
        const lightAutofillStyles = inputStyles[lightAutofillSelector] as Record<
          string,
          unknown
        >;
        const boxShadow = lightAutofillStyles?.WebkitBoxShadow as string;

        // Should use cream background (tertiaryLight)
        expect(boxShadow).toBeDefined();
        expect(boxShadow).toContain('inset');
        expect(boxShadow).toContain(lightScheme.tertiaryLight);
      }
    });
  });
});
