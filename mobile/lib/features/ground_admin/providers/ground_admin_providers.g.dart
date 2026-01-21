// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ground_admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides GroundAdminApi

@ProviderFor(groundAdminApi)
const groundAdminApiProvider = GroundAdminApiProvider._();

/// Provides GroundAdminApi

final class GroundAdminApiProvider
    extends $FunctionalProvider<GroundAdminApi, GroundAdminApi, GroundAdminApi>
    with $Provider<GroundAdminApi> {
  /// Provides GroundAdminApi
  const GroundAdminApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groundAdminApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groundAdminApiHash();

  @$internal
  @override
  $ProviderElement<GroundAdminApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroundAdminApi create(Ref ref) {
    return groundAdminApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroundAdminApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroundAdminApi>(value),
    );
  }
}

String _$groundAdminApiHash() => r'cd7e9aba5d5f7f8fd85154e1580b5d19db0ddb7b';

/// Provides GroundAdminRepository

@ProviderFor(groundAdminRepository)
const groundAdminRepositoryProvider = GroundAdminRepositoryProvider._();

/// Provides GroundAdminRepository

final class GroundAdminRepositoryProvider
    extends
        $FunctionalProvider<
          GroundAdminRepository,
          GroundAdminRepository,
          GroundAdminRepository
        >
    with $Provider<GroundAdminRepository> {
  /// Provides GroundAdminRepository
  const GroundAdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groundAdminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groundAdminRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroundAdminRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GroundAdminRepository create(Ref ref) {
    return groundAdminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroundAdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroundAdminRepository>(value),
    );
  }
}

String _$groundAdminRepositoryHash() =>
    r'd51ed9f0256723c55d062b6653ebc47ab1ffe821';

/// Current user's Ground Admin info (null if not a Ground Admin)

@ProviderFor(MyGroundAdminInfoNotifier)
const myGroundAdminInfoProvider = MyGroundAdminInfoNotifierProvider._();

/// Current user's Ground Admin info (null if not a Ground Admin)
final class MyGroundAdminInfoNotifierProvider
    extends
        $AsyncNotifierProvider<MyGroundAdminInfoNotifier, GroundAdminInfo?> {
  /// Current user's Ground Admin info (null if not a Ground Admin)
  const MyGroundAdminInfoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myGroundAdminInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myGroundAdminInfoNotifierHash();

  @$internal
  @override
  MyGroundAdminInfoNotifier create() => MyGroundAdminInfoNotifier();
}

String _$myGroundAdminInfoNotifierHash() =>
    r'bdb56b5edc91388b2ef4ce48d0b667b07a3fbbf0';

/// Current user's Ground Admin info (null if not a Ground Admin)

abstract class _$MyGroundAdminInfoNotifier
    extends $AsyncNotifier<GroundAdminInfo?> {
  FutureOr<GroundAdminInfo?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<GroundAdminInfo?>, GroundAdminInfo?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GroundAdminInfo?>, GroundAdminInfo?>,
              AsyncValue<GroundAdminInfo?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Whether current user is a Ground Admin

@ProviderFor(isGroundAdmin)
const isGroundAdminProvider = IsGroundAdminProvider._();

/// Whether current user is a Ground Admin

final class IsGroundAdminProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether current user is a Ground Admin
  const IsGroundAdminProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isGroundAdminProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isGroundAdminHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isGroundAdmin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isGroundAdminHash() => r'f648e2520152b43f496a13ac5b81cdcdecc3c107';

/// Manages Ground Admin application and invitation actions

@ProviderFor(GroundAdminActionNotifier)
const groundAdminActionProvider = GroundAdminActionNotifierProvider._();

/// Manages Ground Admin application and invitation actions
final class GroundAdminActionNotifierProvider
    extends
        $NotifierProvider<GroundAdminActionNotifier, GroundAdminActionState> {
  /// Manages Ground Admin application and invitation actions
  const GroundAdminActionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groundAdminActionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groundAdminActionNotifierHash();

  @$internal
  @override
  GroundAdminActionNotifier create() => GroundAdminActionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroundAdminActionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroundAdminActionState>(value),
    );
  }
}

String _$groundAdminActionNotifierHash() =>
    r'b873d1605ec1e2b0fc4d158d44b02d34fa4c99b0';

/// Manages Ground Admin application and invitation actions

abstract class _$GroundAdminActionNotifier
    extends $Notifier<GroundAdminActionState> {
  GroundAdminActionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<GroundAdminActionState, GroundAdminActionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GroundAdminActionState, GroundAdminActionState>,
              GroundAdminActionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
