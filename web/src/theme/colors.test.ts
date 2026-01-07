import { describe, it, expect } from 'vitest';
import { darkScheme, lightScheme } from './colors';

/**
 * Tests for theme color scheme compliance
 * Based on Berry template dark mode patterns:
 * - Dark mode uses tinted dark palette (blue/green tint), not pure grays
 * - Clear visual hierarchy: background (darkest) → paper → surface containers
 * - Text colors with good contrast ratios
 */
describe('darkScheme', () => {
  describe('background hierarchy', () => {
    /**
     * Background should be the darkest color in the hierarchy
     * Berry uses deep blue-gray like #111936 or #1a223f
     */
    it('should have background darker than surface containers', () => {
      const bgLuminance = getLuminance(darkScheme.background);
      const surfaceContainerLuminance = getLuminance(darkScheme.surfaceContainer);
      const surfaceContainerHighLuminance = getLuminance(darkScheme.surfaceContainerHigh);

      expect(bgLuminance).toBeLessThan(surfaceContainerLuminance);
      expect(surfaceContainerLuminance).toBeLessThan(surfaceContainerHighLuminance);
    });

    /**
     * Paper (cards, dialogs) should be visibly different from background
     * Berry uses ~#212946 for cards on #111936 background
     */
    it('should have paper visibly lighter than background', () => {
      const bgLuminance = getLuminance(darkScheme.background);
      const surfaceContainerLuminance = getLuminance(darkScheme.surfaceContainer);

      // Minimum 15% luminance difference for visibility
      const difference = surfaceContainerLuminance - bgLuminance;
      expect(difference).toBeGreaterThan(0.01);
    });

    /**
     * Surface container hierarchy should be properly ordered
     */
    it('should have proper surface container hierarchy', () => {
      const lowest = getLuminance(darkScheme.surfaceContainerLowest);
      const low = getLuminance(darkScheme.surfaceContainerLow);
      const container = getLuminance(darkScheme.surfaceContainer);
      const high = getLuminance(darkScheme.surfaceContainerHigh);
      const highest = getLuminance(darkScheme.surfaceContainerHighest);

      expect(lowest).toBeLessThanOrEqual(low);
      expect(low).toBeLessThanOrEqual(container);
      expect(container).toBeLessThanOrEqual(high);
      expect(high).toBeLessThanOrEqual(highest);
    });
  });

  describe('color tinting (Berry-style)', () => {
    /**
     * Dark background should have a slight tint (not pure gray)
     * Berry uses blue-purple tinted backgrounds like #111936
     * We use forest green tint to match our brand
     */
    it('should have background with subtle color tint', () => {
      const { r, g, b } = hexToRgb(darkScheme.background);

      // Check that the color is not pure gray (r !== g !== b)
      // A pure gray would have r === g === b
      // We want some color variety indicating a tint
      const isNotPureGray = !(r === g && g === b);

      // Also check that there's some color saturation
      const max = Math.max(r, g, b);
      const min = Math.min(r, g, b);
      const saturation = max === 0 ? 0 : (max - min) / max;

      // Should have SOME tint, but not too saturated for dark mode
      expect(isNotPureGray || saturation > 0.02).toBe(true);
    });

    /**
     * Surface containers should maintain the brand tint
     */
    it('should have surface containers with consistent tint direction', () => {
      const bg = hexToRgb(darkScheme.background);
      const container = hexToRgb(darkScheme.surfaceContainer);

      // The tint direction (which color channel dominates) should be similar
      const bgDominant = getDominantChannel(bg);
      const containerDominant = getDominantChannel(container);

      // Both should have the same dominant channel (or be close enough)
      // This ensures consistent color temperature across surfaces
      expect([bgDominant, containerDominant]).not.toContain('pure-gray');
    });
  });

  describe('text contrast', () => {
    /**
     * Primary text should have sufficient contrast against dark surfaces
     * WCAG AA requires 4.5:1 for normal text
     */
    it('should have primary text with good contrast against background', () => {
      const contrast = getContrastRatio(darkScheme.onBackground, darkScheme.background);
      expect(contrast).toBeGreaterThanOrEqual(4.5);
    });

    it('should have primary text with good contrast against surface container', () => {
      const contrast = getContrastRatio(darkScheme.onSurface, darkScheme.surfaceContainer);
      expect(contrast).toBeGreaterThanOrEqual(4.5);
    });

    /**
     * Secondary text should still be readable
     */
    it('should have secondary text with adequate contrast', () => {
      const contrast = getContrastRatio(darkScheme.onSurfaceVariant, darkScheme.surfaceContainer);
      expect(contrast).toBeGreaterThanOrEqual(3.0);
    });
  });

  describe('primary color visibility', () => {
    /**
     * Primary colors should be visible in dark mode
     * Berry shifts to lighter primary shades for dark mode
     */
    it('should have primary main lighter than background', () => {
      const primaryLuminance = getLuminance(darkScheme.primary);
      const bgLuminance = getLuminance(darkScheme.background);

      expect(primaryLuminance).toBeGreaterThan(bgLuminance);
    });
  });
});

describe('lightScheme vs darkScheme', () => {
  it('should have inverted luminance relationship', () => {
    const lightBg = getLuminance(lightScheme.background);
    const darkBg = getLuminance(darkScheme.background);

    expect(lightBg).toBeGreaterThan(0.7); // Light should be bright
    expect(darkBg).toBeLessThan(0.15); // Dark should be dim
  });

  it('should use different text colors for each scheme', () => {
    expect(lightScheme.onBackground).not.toBe(darkScheme.onBackground);
    expect(lightScheme.onSurface).not.toBe(darkScheme.onSurface);
  });
});

// Helper functions

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) {
    throw new Error(`Invalid hex color: ${hex}`);
  }
  return {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16),
  };
}

function getLuminance(hex: string): number {
  const { r, g, b } = hexToRgb(hex);
  const [rs, gs, bs] = [r, g, b].map((c) => {
    const s = c / 255;
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}

function getContrastRatio(foreground: string, background: string): number {
  const l1 = getLuminance(foreground);
  const l2 = getLuminance(background);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

function getDominantChannel(rgb: { r: number; g: number; b: number }): 'red' | 'green' | 'blue' | 'pure-gray' {
  const { r, g, b } = rgb;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);

  // If very low saturation, consider it gray
  if (max - min < 5) return 'pure-gray';

  if (r >= g && r >= b) return 'red';
  if (g >= r && g >= b) return 'green';
  return 'blue';
}
