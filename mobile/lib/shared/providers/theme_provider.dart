import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pod_config.dart';

part 'theme_provider.g.dart';

const _themeModeKey = 'theme_mode';

/// Provides SharedPreferences instance
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return SharedPreferences.getInstance();
}

/// Manages the app's theme mode (light/dark/system)
/// Persists preference to SharedPreferences
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    _loadSavedThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadSavedThemeMode() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final savedMode = prefs.getString(_themeModeKey);
    if (savedMode != null) {
      state = _stringToThemeMode(savedMode);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  void toggleTheme() {
    final newMode = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    setThemeMode(newMode);
  }

  static ThemeMode _stringToThemeMode(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}

/// Provides the current pod configuration
/// In production, this would fetch from API
@Riverpod(keepAlive: true)
PodConfig podConfig(Ref ref) {
  return PodConfig.defaultConfig;
}
