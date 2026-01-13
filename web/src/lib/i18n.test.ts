import { describe, it, expect } from 'vitest';
import { SUPPORTED_LANGUAGES, LANGUAGE_NAMES } from './i18n';

describe('i18n configuration', () => {
  describe('SUPPORTED_LANGUAGES', () => {
    it('should include English', () => {
      expect(SUPPORTED_LANGUAGES).toContain('en');
    });

    it('should include Afrikaans', () => {
      expect(SUPPORTED_LANGUAGES).toContain('af');
    });

    it('should include Zulu', () => {
      expect(SUPPORTED_LANGUAGES).toContain('zu');
    });

    it('should have exactly 3 supported languages', () => {
      expect(SUPPORTED_LANGUAGES).toHaveLength(3);
    });
  });

  describe('LANGUAGE_NAMES', () => {
    it('should have name for English', () => {
      expect(LANGUAGE_NAMES.en).toBe('English');
    });

    it('should have name for Afrikaans', () => {
      expect(LANGUAGE_NAMES.af).toBe('Afrikaans');
    });

    it('should have name for Zulu', () => {
      expect(LANGUAGE_NAMES.zu).toBe('isiZulu');
    });
  });
});
