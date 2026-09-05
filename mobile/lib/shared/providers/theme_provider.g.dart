// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides SharedPreferences instance

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Provides SharedPreferences instance

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  /// Provides SharedPreferences instance
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'50d46e3f8d9f32715d0f3efabdce724e4b2593b4';

/// Manages the app's theme mode (light/dark/system)
/// Persists preference to SharedPreferences

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// Manages the app's theme mode (light/dark/system)
/// Persists preference to SharedPreferences
final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, ThemeMode> {
  /// Manages the app's theme mode (light/dark/system)
  /// Persists preference to SharedPreferences
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'ba095f4dd563fbe0fc53fc98bcba6c85d688e882';

/// Manages the app's theme mode (light/dark/system)
/// Persists preference to SharedPreferences

abstract class _$ThemeModeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Provides the current pod configuration
/// In production, this would fetch from API

@ProviderFor(podConfig)
final podConfigProvider = PodConfigProvider._();

/// Provides the current pod configuration
/// In production, this would fetch from API

final class PodConfigProvider
    extends $FunctionalProvider<PodConfig, PodConfig, PodConfig>
    with $Provider<PodConfig> {
  /// Provides the current pod configuration
  /// In production, this would fetch from API
  PodConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'podConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$podConfigHash();

  @$internal
  @override
  $ProviderElement<PodConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PodConfig create(Ref ref) {
    return podConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PodConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PodConfig>(value),
    );
  }
}

String _$podConfigHash() => r'e55f74f9a4f905e84b101eb54333c4fa460d7a34';
