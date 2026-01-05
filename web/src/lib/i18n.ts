import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// Import translation files
import enTranslation from '@/locales/en/translation.json';

// Supported languages - MVP starts with English only
// Future: Add 11 South African languages (af, zu, xh, st, tn, ts, ss, ve, nr, nso)
export const SUPPORTED_LANGUAGES = ['en'] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

export const LANGUAGE_NAMES: Record<SupportedLanguage, string> = {
  en: 'English',
  // Future languages:
  // af: 'Afrikaans',
  // zu: 'isiZulu',
  // xh: 'isiXhosa',
  // st: 'Sesotho',
  // tn: 'Setswana',
  // ts: 'Xitsonga',
  // ss: 'siSwati',
  // ve: 'Tshivenda',
  // nr: 'isiNdebele',
  // nso: 'Sepedi',
};

const resources = {
  en: {
    translation: enTranslation,
  },
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'en', // Default language
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false, // React already escapes values
  },
  react: {
    useSuspense: true,
  },
});

export default i18n;
