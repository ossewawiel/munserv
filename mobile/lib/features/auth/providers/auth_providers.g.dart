// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides FlutterSecureStorage instance

@ProviderFor(flutterSecureStorage)
const flutterSecureStorageProvider = FlutterSecureStorageProvider._();

/// Provides FlutterSecureStorage instance

final class FlutterSecureStorageProvider
    extends
        $FunctionalProvider<
          FlutterSecureStorage,
          FlutterSecureStorage,
          FlutterSecureStorage
        >
    with $Provider<FlutterSecureStorage> {
  /// Provides FlutterSecureStorage instance
  const FlutterSecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flutterSecureStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flutterSecureStorageHash();

  @$internal
  @override
  $ProviderElement<FlutterSecureStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterSecureStorage create(Ref ref) {
    return flutterSecureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterSecureStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterSecureStorage>(value),
    );
  }
}

String _$flutterSecureStorageHash() =>
    r'e185811e78dc96d64925adeaa0b81a3ca8883fcc';

/// Provides SecureStorageService

@ProviderFor(secureStorage)
const secureStorageProvider = SecureStorageProvider._();

/// Provides SecureStorageService

final class SecureStorageProvider
    extends
        $FunctionalProvider<
          SecureStorageService,
          SecureStorageService,
          SecureStorageService
        >
    with $Provider<SecureStorageService> {
  /// Provides SecureStorageService
  const SecureStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageHash();

  @$internal
  @override
  $ProviderElement<SecureStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SecureStorageService create(Ref ref) {
    return secureStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureStorageService>(value),
    );
  }
}

String _$secureStorageHash() => r'0a0dbbdab35d34cfd77089513684538299f16d9f';

/// Provides AuthApi

@ProviderFor(authApi)
const authApiProvider = AuthApiProvider._();

/// Provides AuthApi

final class AuthApiProvider
    extends $FunctionalProvider<AuthApi, AuthApi, AuthApi>
    with $Provider<AuthApi> {
  /// Provides AuthApi
  const AuthApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authApiHash();

  @$internal
  @override
  $ProviderElement<AuthApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthApi create(Ref ref) {
    return authApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthApi>(value),
    );
  }
}

String _$authApiHash() => r'ac66c1c9810f43bc53db0d8c94d4bfaa679a0734';

/// Provides AuthRepository

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

/// Provides AuthRepository

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Provides AuthRepository
  const AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'd6de7e5efa41eeb51d360f337179ed4d5e76e889';

/// Manages authentication state throughout the app

@ProviderFor(AuthNotifier)
const authProvider = AuthNotifierProvider._();

/// Manages authentication state throughout the app
final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AuthState> {
  /// Manages authentication state throughout the app
  const AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authNotifierHash() => r'b8fdb2a528a66ccb94dfab75c00ee6ceb841cac4';

/// Manages authentication state throughout the app

abstract class _$AuthNotifier extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provides the current authentication status

@ProviderFor(isAuthenticated)
const isAuthenticatedProvider = IsAuthenticatedProvider._();

/// Provides the current authentication status

final class IsAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provides the current authentication status
  const IsAuthenticatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAuthenticatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAuthenticatedHash() => r'003f7e85bfa5ae774792659ce771b5b59ebf04f8';

/// Provides the current user profile if authenticated

@ProviderFor(currentProfile)
const currentProfileProvider = CurrentProfileProvider._();

/// Provides the current user profile if authenticated

final class CurrentProfileProvider
    extends $FunctionalProvider<MemberProfile?, MemberProfile?, MemberProfile?>
    with $Provider<MemberProfile?> {
  /// Provides the current user profile if authenticated
  const CurrentProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentProfileHash();

  @$internal
  @override
  $ProviderElement<MemberProfile?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemberProfile? create(Ref ref) {
    return currentProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberProfile? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberProfile?>(value),
    );
  }
}

String _$currentProfileHash() => r'fff7b658f93674dcfe44ec35273b2dc3f1ee3407';

/// Provides the current access token if authenticated

@ProviderFor(accessToken)
const accessTokenProvider = AccessTokenProvider._();

/// Provides the current access token if authenticated

final class AccessTokenProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Provides the current access token if authenticated
  const AccessTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessTokenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessTokenHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return accessToken(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$accessTokenHash() => r'3371e484bbd4a5577c005f4adc96d39b2e0b29c6';

/// Provides the stored phone number for login convenience

@ProviderFor(storedPhoneNumber)
const storedPhoneNumberProvider = StoredPhoneNumberProvider._();

/// Provides the stored phone number for login convenience

final class StoredPhoneNumberProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the stored phone number for login convenience
  const StoredPhoneNumberProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storedPhoneNumberProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storedPhoneNumberHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return storedPhoneNumber(ref);
  }
}

String _$storedPhoneNumberHash() => r'eb265dcd0652314b3d9627883034892442c31cef';
