import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// Import translation files
import enTranslation from '@/locales/en/translation.json';
import afTranslation from '@/locales/af/translation.json';
import zuTranslation from '@/locales/zu/translation.json';

// LocalStorage key for persisting language preference
const LANGUAGE_STORAGE_KEY = 'munserv-language';

// Supported languages - English, Afrikaans, and Zulu
// Future: Add more South African languages (xh, st, tn, ts, ss, ve, nr, nso)
export const SUPPORTED_LANGUAGES = ['en', 'af', 'zu'] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

export const LANGUAGE_NAMES: Record<SupportedLanguage, string> = {
  en: 'English',
  af: 'Afrikaans',
  zu: 'isiZulu',
  // Future languages:
  // xh: 'isiXhosa',
  // st: 'Sesotho',
  // tn: 'Setswana',
  // ts: 'Xitsonga',
  // ss: 'siSwati',
  // ve: 'Tshivenda',
  // nr: 'isiNdebele',
  // nso: 'Sepedi',
};

/** Native language names displayed in their own script */
export const LANGUAGE_NATIVE_NAMES: Record<SupportedLanguage, string> = {
  en: 'English',
  af: 'Afrikaans',
  zu: 'isiZulu',
};

const resources = {
  en: {
    translation: enTranslation,
  },
  af: {
    translation: afTranslation,
  },
  zu: {
    translation: zuTranslation,
  },
};

/**
 * Get the initial language from localStorage or default to 'en'
 */
function getInitialLanguage(): SupportedLanguage {
  try {
    const stored = localStorage.getItem(LANGUAGE_STORAGE_KEY);
    if (stored && SUPPORTED_LANGUAGES.includes(stored as SupportedLanguage)) {
      return stored as SupportedLanguage;
    }
  } catch {
    // localStorage may not be available (SSR, privacy mode)
  }
  return 'en';
}

i18n.use(initReactI18next).init({
  resources,
  lng: getInitialLanguage(),
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false, // React already escapes values
  },
  react: {
    useSuspense: true,
  },
});

// Persist language changes to localStorage
i18n.on('languageChanged', (lng: string) => {
  try {
    localStorage.setItem(LANGUAGE_STORAGE_KEY, lng);
  } catch {
    // localStorage may not be available
  }
});

export { default } from 'i18next';
