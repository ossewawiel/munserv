// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_accounts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Demo accounts baked into this build by `--dart-define-from-file`.
/// Empty on a normal build, so the login page offers no quick login.

@ProviderFor(demoAccounts)
final demoAccountsProvider = DemoAccountsProvider._();

/// Demo accounts baked into this build by `--dart-define-from-file`.
/// Empty on a normal build, so the login page offers no quick login.

final class DemoAccountsProvider
    extends
        $FunctionalProvider<
          List<DemoAccount>,
          List<DemoAccount>,
          List<DemoAccount>
        >
    with $Provider<List<DemoAccount>> {
  /// Demo accounts baked into this build by `--dart-define-from-file`.
  /// Empty on a normal build, so the login page offers no quick login.
  DemoAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoAccountsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoAccountsHash();

  @$internal
  @override
  $ProviderElement<List<DemoAccount>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<DemoAccount> create(Ref ref) {
    return demoAccounts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DemoAccount> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DemoAccount>>(value),
    );
  }
}

String _$demoAccountsHash() => r'5e9edf72c716df1b20908128986ec38bf2f47577';
