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

String _$authRepositoryHash() => r'2775d29e1d12d27bc8a6b1ba462dc9f8d37f4203';

/// Manages authentication state throughout the app
/// Updated for email + password authentication (Web Registration Flow)

@ProviderFor(AuthNotifier)
const authProvider = AuthNotifierProvider._();

/// Manages authentication state throughout the app
/// Updated for email + password authentication (Web Registration Flow)
final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AuthState> {
  /// Manages authentication state throughout the app
  /// Updated for email + password authentication (Web Registration Flow)
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

String _$authNotifierHash() => r'53d285815119d3ae67b02c701b9c799ac4b18940';

/// Manages authentication state throughout the app
/// Updated for email + password authentication (Web Registration Flow)

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

/// Provides the stored email for login convenience (web registration flow)

@ProviderFor(storedEmail)
const storedEmailProvider = StoredEmailProvider._();

/// Provides the stored email for login convenience (web registration flow)

final class StoredEmailProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the stored email for login convenience (web registration flow)
  const StoredEmailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storedEmailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storedEmailHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return storedEmail(ref);
  }
}

String _$storedEmailHash() => r'a02cfd1519bede421c538833dcc974830431830d';

/// Check if user can use quick login (PIN/biometric) instead of email/password
/// Returns true if email, password, and PIN are all stored

@ProviderFor(canUseQuickLogin)
const canUseQuickLoginProvider = CanUseQuickLoginProvider._();

/// Check if user can use quick login (PIN/biometric) instead of email/password
/// Returns true if email, password, and PIN are all stored

final class CanUseQuickLoginProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Check if user can use quick login (PIN/biometric) instead of email/password
  /// Returns true if email, password, and PIN are all stored
  const CanUseQuickLoginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canUseQuickLoginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canUseQuickLoginHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return canUseQuickLogin(ref);
  }
}

String _$canUseQuickLoginHash() => r'4629fe59159d0ffdf7d43f4c30aa24c631464d0c';

/// Quick login eligibility state - used by router for synchronous redirect decisions
/// This is initialized at app startup and updated when auth state changes

@ProviderFor(QuickLoginEligibility)
const quickLoginEligibilityProvider = QuickLoginEligibilityProvider._();

/// Quick login eligibility state - used by router for synchronous redirect decisions
/// This is initialized at app startup and updated when auth state changes
final class QuickLoginEligibilityProvider
    extends $NotifierProvider<QuickLoginEligibility, bool?> {
  /// Quick login eligibility state - used by router for synchronous redirect decisions
  /// This is initialized at app startup and updated when auth state changes
  const QuickLoginEligibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickLoginEligibilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickLoginEligibilityHash();

  @$internal
  @override
  QuickLoginEligibility create() => QuickLoginEligibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool?>(value),
    );
  }
}

String _$quickLoginEligibilityHash() =>
    r'baaf5e034c31a4243862f6cfcb8241f0b5457a96';

/// Quick login eligibility state - used by router for synchronous redirect decisions
/// This is initialized at app startup and updated when auth state changes

abstract class _$QuickLoginEligibility extends $Notifier<bool?> {
  bool? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool?, bool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool?, bool?>,
              bool?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Temporary PIN storage for biometric setup after login
/// This is cleared after use or on app restart

@ProviderFor(TempPinForBiometricSetup)
const tempPinForBiometricSetupProvider = TempPinForBiometricSetupProvider._();

/// Temporary PIN storage for biometric setup after login
/// This is cleared after use or on app restart
final class TempPinForBiometricSetupProvider
    extends $NotifierProvider<TempPinForBiometricSetup, String?> {
  /// Temporary PIN storage for biometric setup after login
  /// This is cleared after use or on app restart
  const TempPinForBiometricSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tempPinForBiometricSetupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tempPinForBiometricSetupHash();

  @$internal
  @override
  TempPinForBiometricSetup create() => TempPinForBiometricSetup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$tempPinForBiometricSetupHash() =>
    r'e3fe5ec31572ffe669a932427abbc38721e5c9bc';

/// Temporary PIN storage for biometric setup after login
/// This is cleared after use or on app restart

abstract class _$TempPinForBiometricSetup extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Check if biometric login is enabled for this user

@ProviderFor(isBiometricLoginEnabled)
const isBiometricLoginEnabledProvider = IsBiometricLoginEnabledProvider._();

/// Check if biometric login is enabled for this user

final class IsBiometricLoginEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Check if biometric login is enabled for this user
  const IsBiometricLoginEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isBiometricLoginEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isBiometricLoginEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isBiometricLoginEnabled(ref);
  }
}

String _$isBiometricLoginEnabledHash() =>
    r'7745400042f70b89557664870cc062ee4842e21a';

/// Enable biometric login with the user's PIN

@ProviderFor(BiometricLoginNotifier)
const biometricLoginProvider = BiometricLoginNotifierProvider._();

/// Enable biometric login with the user's PIN
final class BiometricLoginNotifierProvider
    extends $AsyncNotifierProvider<BiometricLoginNotifier, void> {
  /// Enable biometric login with the user's PIN
  const BiometricLoginNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricLoginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricLoginNotifierHash();

  @$internal
  @override
  BiometricLoginNotifier create() => BiometricLoginNotifier();
}

String _$biometricLoginNotifierHash() =>
    r'c116c15e42e5f3b696ca1c4e36e89f0779928ff4';

/// Enable biometric login with the user's PIN

abstract class _$BiometricLoginNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
