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
import '../domain/auth_types.dart';
import '../domain/member_login_response.dart';

part 'auth_providers.g.dart';

// =============================================================================
// Infrastructure Providers
// =============================================================================

/// Provides FlutterSecureStorage instance
@riverpod
FlutterSecureStorage flutterSecureStorage(Ref ref) {
  return const FlutterSecureStorage(
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
/// Updated for email + password authentication (Web Registration Flow)
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
      // Validate stored tokens by calling /members/me
      // This ensures we don't auto-login with expired/invalid tokens
      try {
        final api = ref.read(authApiProvider);
        final meResponse = await api.getMe();

        // Tokens are valid - use fresh profile from server
        state = AuthState.authenticated(
          tokens: tokens,
          profile: meResponse.toMemberProfile(),
          sector: SectorInfo(
            id: meResponse.sectorId,
            name: 'Unknown', // Sector name not returned by /me endpoint
            center: const GeoPoint(latitude: 0, longitude: 0),
          ),
        );
      } catch (e) {
        // Token validation failed - clear session and require re-login
        await _storage.clearSession();
        state = const AuthState.unauthenticated();
      }
    } else {
      state = const AuthState.unauthenticated();
    }
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

  /// Logout - clear session
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

  // ===============================
  // Email + Password Login (Web Registration Flow)
  // ===============================

  /// Login with email and password
  /// Used for members who registered via web portal
  Future<Result<MemberLoginResponse>> loginWithEmail(
    String email,
    String password, {
    bool savePasswordForQuickLogin = true,
  }) async {
    // Don't change auth state to loading - the UI handles loading state locally
    // This prevents router from rebuilding the page and losing local state

    final result = await _repository.loginWithEmail(
      email: email,
      password: password,
    );

    result.when(
      success: (response) async {
        // Save email for future login convenience
        await _storage.saveEmail(email);

        // Save password for quick login (encrypted in secure storage)
        if (savePasswordForQuickLogin) {
          await _storage.savePassword(password);
        }

        // Create tokens from response
        final tokens = AuthTokens.fromMemberLoginResponse(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          expiresIn: response.expiresIn,
        );

        // Save tokens
        await _storage.saveTokens(tokens);

        if (response.mustChangePassword) {
          // User must change password before proceeding
          state = AuthState.mustChangePassword(
            tokens: tokens,
            memberId: response.memberId,
          );
        } else {
          // Check if PIN is already set up
          final hasPin = await _storage.getPin() != null;

          if (hasPin) {
            // Fully authenticated, fetch profile
            await _fetchAndSetProfile(tokens);
          } else {
            // Need PIN setup
            state = AuthState.pendingPinSetup(
              tokens: tokens,
              memberId: response.memberId,
            );
          }
        }
      },
      failure: (error) {
        // Don't set auth state to error - the page displays the error via Result
        // Setting AuthState.error would trigger router refresh and rebuild the page,
        // losing the error message stored in local widget state
      },
    );

    return result;
  }

  /// Change password (for first-time login after web registration)
  Future<Result<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final currentState = state;
    if (currentState is! AuthStateMustChangePassword) {
      return Result.failure(
        const AppError.validation(message: 'Must be in password change state'),
      );
    }

    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    result.when(
      success: (_) {
        // Password changed, now need PIN setup
        state = AuthState.pendingPinSetup(
          tokens: currentState.tokens,
          memberId: currentState.memberId,
        );
      },
      failure: (error) {
        // Stay in mustChangePassword state, show error temporarily
        state = AuthState.error(error.displayMessage);
        // Restore previous state after showing error
        Future.delayed(const Duration(seconds: 2), () {
          state = currentState;
        });
      },
    );

    return result;
  }

  /// Complete PIN setup and fully authenticate
  Future<void> completePinSetup(String pin) async {
    final currentState = state;

    if (currentState is! AuthStatePendingPinSetup) {
      return;
    }

    // Save PIN
    await _storage.savePin(pin);

    // Fetch profile and complete authentication
    await _fetchAndSetProfile(currentState.tokens);
  }

  // ===============================
  // Quick Login (PIN/Biometric)
  // ===============================

  /// Quick login using PIN - validates PIN and re-authenticates with saved credentials
  Future<Result<void>> quickLoginWithPin(String enteredPin) async {
    // Verify PIN matches stored PIN
    final storedPin = await _storage.getPin();
    if (storedPin == null || enteredPin != storedPin) {
      return const Result.failure(AppError.validation(message: 'Invalid PIN'));
    }

    // Get saved credentials
    final email = await _storage.getEmail();
    final password = await _storage.getPassword();

    if (email == null || password == null) {
      return const Result.failure(
        AppError.validation(
          message: 'Saved credentials not found. Please login again.',
        ),
      );
    }

    // Re-authenticate with saved credentials
    final result = await loginWithEmail(
      email,
      password,
      savePasswordForQuickLogin: false, // Already saved
    );

    return result.when(
      success: (_) => const Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }

  /// Clear quick login data (used when switching accounts)
  Future<void> clearQuickLoginData() async {
    await _storage.clearQuickLoginData();
    state = const AuthState.unauthenticated();
    // Invalidate quick login provider
    ref.invalidate(canUseQuickLoginProvider);
  }

  /// Fetch profile and set authenticated state
  Future<void> _fetchAndSetProfile(AuthTokens tokens) async {
    final result = await _repository.getMe();

    result.when(
      success: (response) async {
        final profile = response.toMemberProfile();

        // Save profile to storage
        await _storage.saveProfile(profile);

        // Fetch sector info
        final api = ref.read(authApiProvider);
        try {
          final sector = await api.getSector(response.sectorId);
          state = AuthState.authenticated(
            tokens: tokens,
            profile: profile,
            sector: sector,
          );
        } catch (e) {
          // If sector fetch fails, use placeholder
          state = AuthState.authenticated(
            tokens: tokens,
            profile: profile,
            sector: SectorInfo(
              id: response.sectorId,
              name: 'Unknown',
              center: const GeoPoint(latitude: 0, longitude: 0),
            ),
          );
        }
      },
      failure: (error) {
        state = AuthState.error(error.displayMessage);
      },
    );
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

/// Provides the stored email for login convenience (web registration flow)
@riverpod
Future<String?> storedEmail(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.getEmail();
}

/// Check if user can use quick login (PIN/biometric) instead of email/password
/// Returns true if email, password, and PIN are all stored
@riverpod
Future<bool> canUseQuickLogin(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.hasQuickLoginCredentials();
}

/// Quick login eligibility state - used by router for synchronous redirect decisions
/// This is initialized at app startup and updated when auth state changes
@Riverpod(keepAlive: true)
class QuickLoginEligibility extends _$QuickLoginEligibility {
  @override
  bool? build() {
    // Check eligibility asynchronously and update state
    _checkEligibility();
    return null; // Initial state is unknown
  }

  Future<void> _checkEligibility() async {
    final storage = ref.read(secureStorageProvider);
    final isEligible = await storage.hasQuickLoginCredentials();
    state = isEligible;
  }

  /// Mark as not eligible (used when user chooses to use different account)
  void markNotEligible() {
    state = false;
  }

  /// Refresh eligibility check
  Future<void> refresh() async {
    await _checkEligibility();
  }
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
          const AppError.validation(
            message: 'Biometrics not available on this device',
          ),
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
      final errorMsg =
          authResult.errorMessage ?? 'Biometric authentication failed';
      if (ref.mounted) {
        state = AsyncError(
          AppError.unauthorized(message: errorMsg),
          StackTrace.current,
        );
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
      final errorMsg =
          authResult.errorMessage ?? 'Biometric authentication failed';
      if (ref.mounted) {
        state = AsyncError(
          AppError.unauthorized(message: errorMsg),
          StackTrace.current,
        );
      }
      return Result.failure(AppError.unauthorized(message: errorMsg));
    }

    // Get the stored PIN
    final pin = await storage.getBiometricPin();
    if (pin == null) {
      if (ref.mounted) {
        state = AsyncError(
          const AppError.validation(
            message: 'No PIN stored for biometric login',
          ),
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
