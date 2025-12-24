import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'theme_provider.dart';

part 'locale_provider.g.dart';

const _localeKey = 'locale';

/// Manages the app's locale (language)
/// Persists preference to SharedPreferences
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale? build() {
    _loadSavedLocale();
    return null; // null means use system locale
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (locale != null) {
      await prefs.setString(_localeKey, locale.languageCode);
    } else {
      await prefs.remove(_localeKey);
    }
  }

  /// Reset to system locale
  Future<void> useSystemLocale() async {
    await setLocale(null);
  }
}

/// South African official languages
/// Used for Phase 2 multi-language support
class SouthAfricanLocales {
  static const Locale english = Locale('en');
  static const Locale afrikaans = Locale('af');
  static const Locale isiNdebele = Locale('nr');
  static const Locale isiXhosa = Locale('xh');
  static const Locale isiZulu = Locale('zu');
  static const Locale sepedi = Locale('nso');
  static const Locale sesotho = Locale('st');
  static const Locale setswana = Locale('tn');
  static const Locale siSwati = Locale('ss');
  static const Locale tshivenda = Locale('ve');
  static const Locale xitsonga = Locale('ts');

  static const List<Locale> all = [
    english,
    afrikaans,
    isiNdebele,
    isiXhosa,
    isiZulu,
    sepedi,
    sesotho,
    setswana,
    siSwati,
    tshivenda,
    xitsonga,
  ];

  static String getDisplayName(Locale locale) {
    return switch (locale.languageCode) {
      'en' => 'English',
      'af' => 'Afrikaans',
      'nr' => 'isiNdebele',
      'xh' => 'isiXhosa',
      'zu' => 'isiZulu',
      'nso' => 'Sepedi',
      'st' => 'Sesotho',
      'tn' => 'Setswana',
      'ss' => 'siSwati',
      've' => 'Tshivenda',
      'ts' => 'Xitsonga',
      _ => locale.languageCode,
    };
  }
}
