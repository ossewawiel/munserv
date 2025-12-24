// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the app's locale (language)
/// Persists preference to SharedPreferences

@ProviderFor(LocaleNotifier)
const localeProvider = LocaleNotifierProvider._();

/// Manages the app's locale (language)
/// Persists preference to SharedPreferences
final class LocaleNotifierProvider
    extends $NotifierProvider<LocaleNotifier, Locale?> {
  /// Manages the app's locale (language)
  /// Persists preference to SharedPreferences
  const LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale?>(value),
    );
  }
}

String _$localeNotifierHash() => r'651702fd532a1738f069a7f7a2e0c9215e163ef2';

/// Manages the app's locale (language)
/// Persists preference to SharedPreferences

abstract class _$LocaleNotifier extends $Notifier<Locale?> {
  Locale? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Locale?, Locale?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale?, Locale?>,
              Locale?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
