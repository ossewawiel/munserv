import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/models/geo_point.dart';
import '../../../shared/providers/dio_provider.dart';
import '../../../shared/services/biometric_service.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../data/secure_storage.dart';
import '../domain/auth_state.dart';
import '../domain/login_request.dart';
import '../domain/otp_request.dart';
import '../domain/otp_verify_result.dart';

part 'auth_providers.g.dart';

// =============================================================================
// Infrastructure Providers
// =============================================================================

/// Provides FlutterSecureStorage instance
@riverpod
FlutterSecureStorage flutterSecureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}

/// Provides SecureStorageService
@riverpod
SecureStorageService secureStorage(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorageService(storage);
}

/// Provides AuthApi
@riverpod
AuthApi authApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return AuthApi(dio);
}

/// Provides AuthRepository
@riverpod
AuthRepository authRepository(Ref ref) {
  final api = ref.watch(authApiProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(api, storage);
}

// =============================================================================
// Auth State Notifier
// =============================================================================

/// Manages authentication state throughout the app
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Check for existing session on startup
    _checkExistingSession();
    return const AuthState.initial();
  }

  SecureStorageService get _storage => ref.read(secureStorageProvider);
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Check if user has a valid session stored
  Future<void> _checkExistingSession() async {
    final tokens = await _storage.getTokens();
    final profile = await _storage.getProfile();

    if (tokens != null && profile != null) {
      // We have stored credentials - try to validate them
      // For MVP, we trust the stored tokens without server validation
      // In production, we'd call a /me endpoint to validate
      state = AuthState.authenticated(
        tokens: tokens,
        profile: profile,
        sector: const SectorInfo(
          id: 'unknown',
          name: 'Unknown',
          center: GeoPoint(latitude: 0, longitude: 0),
        ),
      );
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  /// Request OTP for phone number
  Future<Result<OtpRequestResponse>> requestOtp(String phoneNumber) async {
    return _repository.requestOtp(phoneNumber);
  }

  /// Verify OTP code
  /// For backend flow: existing users need to login with PIN separately
  /// For mock API flow: existing users get tokens immediately
  Future<Result<OtpVerifyResult>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    final result = await _repository.verifyOtp(phoneNumber, otp);

    // For mock API flow: If existing user has tokens, they're logged in
    // For backend flow: tokens/profile are null, user must login with PIN
    if (result.isSuccess) {
      final verifyResult = result.dataOrNull!;
      if (verifyResult.isExistingUser && verifyResult.hasTokens) {
        final existing = verifyResult as OtpVerifyResultExistingUser;
        // Mock API returns tokens immediately
        await _handleSuccessfulAuth(
          existing.tokens!,
          existing.profile!.member,
          existing.profile!.sector,
        );
        // Save phone number for quick re-login after logout
        await _storage.savePhoneNumber(phoneNumber);
      }
      // For backend flow: just save phone number, user will login with PIN
      if (verifyResult.isExistingUser && !verifyResult.hasTokens) {
        await _storage.savePhoneNumber(phoneNumber);
      }
    }

    return result;
  }

  /// Complete registration for new user
  /// For backend: phoneNumber and sectorId are required
  /// tempToken is kept for mock API compatibility but not used by backend
  Future<Result<AuthResponse>> completeRegistration({
    required String phoneNumber,
    required String firstName,
    required String surname,
    required String pin,
    required GeoPoint location,
    required String address,
    required String sectorId,
    String? tempToken, // Optional: used by mock API, ignored by backend
  }) async {
    state = const AuthState.loading();

    final result = await _repository.completeRegistration(
      phoneNumber: phoneNumber,
      firstName: firstName,
      surname: surname,
      pin: pin,
      location: location,
      address: address,
      sectorId: sectorId,
    );

    if (result.isSuccess) {
      final response = result.dataOrNull!;
      await _handleSuccessfulAuth(
        response.tokens,
        response.profile.member,
        response.profile.sector,
      );
      // Save phone number for quick re-login after logout
      await _storage.savePhoneNumber(phoneNumber);
    } else {
      state = AuthState.error(result.errorOrNull?.displayMessage ?? 'Registration failed');
    }

    return result;
  }

  /// Login with phone and PIN
  Future<Result<AuthResponse>> login(String phoneNumber, String pin) async {
    state = const AuthState.loading();

    final result = await _repository.login(phoneNumber, pin);

    if (result.isSuccess) {
      final response = result.dataOrNull!;
      // Store PIN FIRST before auth state change triggers navigation
      ref.read(tempPinForBiometricSetupProvider.notifier).setPin(pin);
      // Save phone number for convenience
      await _storage.savePhoneNumber(phoneNumber);
      // This updates auth state which triggers router redirect
      await _handleSuccessfulAuth(
        response.tokens,
        response.profile.member,
        response.profile.sector,
      );
    } else {
      state = AuthState.error(result.errorOrNull?.displayMessage ?? 'Login failed');
    }

    return result;
  }

  /// Handle successful authentication
  Future<void> _handleSuccessfulAuth(
    AuthTokens tokens,
    MemberProfile profile,
    SectorInfo sector,
  ) async {
    // Save to secure storage
    await _storage.saveTokens(tokens);
    await _storage.saveProfile(profile);

    // Update state
    state = AuthState.authenticated(
      tokens: tokens,
      profile: profile,
      sector: sector,
    );
  }

  /// Refresh access token
  Future<Result<AuthTokens>> refreshToken() async {
    final currentTokens = await _storage.getTokens();
    if (currentTokens == null) {
      return Result.failure(
        const AppError.unauthorized(message: 'No refresh token available'),
      );
    }

    final result = await _repository.refreshToken(currentTokens.refreshToken);

    if (result.isSuccess) {
      final newTokens = result.dataOrNull!;
      await _storage.saveTokens(newTokens);

      // Update state with new tokens
      final currentState = state;
      if (currentState is AuthStateAuthenticated) {
        state = AuthState.authenticated(
          tokens: newTokens,
          profile: currentState.profile,
          sector: currentState.sector,
        );
      }
    }

    return result;
  }

  /// Logout - clear session but keep phone number for quick re-login
  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState.unauthenticated();
  }

  /// Clear error state and return to unauthenticated
  void clearError() {
    if (state is AuthStateError) {
      state = const AuthState.unauthenticated();
    }
  }
}

// =============================================================================
// Convenience Providers
// =============================================================================

/// Provides the current authentication status
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
}

/// Provides the current user profile if authenticated
@riverpod
MemberProfile? currentProfile(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState.profileOrNull;
}

/// Provides the current access token if authenticated
@riverpod
String? accessToken(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState.accessTokenOrNull;
}

/// Provides the stored phone number for login convenience
@riverpod
Future<String?> storedPhoneNumber(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.getPhoneNumber();
}

// =============================================================================
// Biometric Authentication Providers
// =============================================================================

/// Temporary PIN storage for biometric setup after login
/// This is cleared after use or on app restart
@Riverpod(keepAlive: true)
class TempPinForBiometricSetup extends _$TempPinForBiometricSetup {
  @override
  String? build() => null;

  void setPin(String? pin) {
    state = pin;
  }

  void clear() {
    state = null;
  }
}

/// Check if biometric login is enabled for this user
@riverpod
Future<bool> isBiometricLoginEnabled(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  final biometricService = ref.watch(biometricServiceProvider);

  // Must have biometric enabled in storage AND device must support it
  final userEnabled = await storage.isBiometricEnabled();
  if (!userEnabled) return false;

  final deviceAvailable = await biometricService.isBiometricAvailable();
  return deviceAvailable;
}

/// Enable biometric login with the user's PIN
@Riverpod(keepAlive: true)
class BiometricLoginNotifier extends _$BiometricLoginNotifier {
  @override
  FutureOr<void> build() {}

  /// Enable biometric login by storing the PIN
  Future<Result<void>> enableBiometric(String pin) async {
    // Cache dependencies before async operations to avoid ref access after disposal
    final storage = ref.read(secureStorageProvider);
    final biometricService = ref.read(biometricServiceProvider);

    state = const AsyncLoading();

    // First verify biometrics are available
    final isAvailable = await biometricService.isBiometricAvailable();
    if (!isAvailable) {
      if (ref.mounted) {
        state = AsyncError(
          const AppError.validation(message: 'Biometrics not available on this device'),
          StackTrace.current,
        );
      }
      return const Result.failure(
        AppError.validation(message: 'Biometrics not available on this device'),
      );
    }

    // Authenticate to confirm user identity
    final authResult = await biometricService.authenticate(
      localizedReason: 'Authenticate to enable biometric login',
    );

    if (!authResult.isSuccess) {
      final errorMsg = authResult.errorMessage ?? 'Biometric authentication failed';
      if (ref.mounted) {
        state = AsyncError(AppError.unauthorized(message: errorMsg), StackTrace.current);
      }
      return Result.failure(AppError.unauthorized(message: errorMsg));
    }

    // Store the PIN for biometric login
    await storage.enableBiometric(pin);

    // Invalidate the enabled state provider to refresh
    if (ref.mounted) {
      ref.invalidate(isBiometricLoginEnabledProvider);
      state = const AsyncData(null);
    }
    return const Result.success(null);
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    final storage = ref.read(secureStorageProvider);
    await storage.disableBiometric();
    if (ref.mounted) {
      ref.invalidate(isBiometricLoginEnabledProvider);
    }
  }

  /// Perform biometric login - returns the stored PIN on success
  Future<Result<String>> authenticateAndGetPin() async {
    // Cache dependencies before async operations
    final storage = ref.read(secureStorageProvider);
    final biometricService = ref.read(biometricServiceProvider);

    state = const AsyncLoading();

    // Check if biometric login is enabled
    final isEnabled = await storage.isBiometricEnabled();
    if (!isEnabled) {
      if (ref.mounted) {
        state = AsyncError(
          const AppError.validation(message: 'Biometric login not enabled'),
          StackTrace.current,
        );
      }
      return const Result.failure(
        AppError.validation(message: 'Biometric login not enabled'),
      );
    }

    // Authenticate
    final authResult = await biometricService.authenticate(
      localizedReason: 'Authenticate to login',
    );

    if (!authResult.isSuccess) {
      final errorMsg = authResult.errorMessage ?? 'Biometric authentication failed';
      if (ref.mounted) {
        state = AsyncError(AppError.unauthorized(message: errorMsg), StackTrace.current);
      }
      return Result.failure(AppError.unauthorized(message: errorMsg));
    }

    // Get the stored PIN
    final pin = await storage.getBiometricPin();
    if (pin == null) {
      if (ref.mounted) {
        state = AsyncError(
          const AppError.validation(message: 'No PIN stored for biometric login'),
          StackTrace.current,
        );
      }
      return const Result.failure(
        AppError.validation(message: 'No PIN stored for biometric login'),
      );
    }

    if (ref.mounted) {
      state = const AsyncData(null);
    }
    return Result.success(pin);
  }
}
