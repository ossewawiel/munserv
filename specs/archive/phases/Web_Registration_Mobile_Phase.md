# Web Registration - Mobile Phase Implementation

**Feature:** Member Registration via Web with Admin Approval
**Phase:** Mobile App (3 of 3)
**Status:** Ready for Implementation
**Dependencies:** Backend Phase must be completed first

---

## 1. Overview

This phase implements the Flutter mobile app changes to support the new email+password authentication flow. It removes OTP-based registration and adds first-time password change functionality.

### 1.1 Goals
- Remove OTP-based phone registration screens
- Implement email + password login
- Add first-time password change screen
- Keep existing PIN setup after password authentication
- Keep biometric login option after PIN setup

### 1.2 New Authentication Flow
```
Email Login → (if mustChangePassword) → Change Password → PIN Setup → (Optional) Biometric Setup → Home
```

### 1.3 Files to Remove
- `lib/features/auth/presentation/pages/phone_entry_page.dart`
- `lib/features/auth/presentation/pages/otp_verify_page.dart`
- `lib/features/auth/presentation/pages/registration_page.dart`
- `lib/features/auth/presentation/widgets/otp_input_field.dart`
- `lib/features/auth/presentation/widgets/phone_input_field.dart`
- `lib/features/auth/domain/otp_request.dart`
- `lib/features/auth/domain/otp_verify_result.dart`
- `lib/features/auth/domain/check_phone_response.dart`

---

## 2. Domain Layer Changes

### 2.1 New MemberLoginResponse Model

**New File:** `lib/features/auth/domain/member_login_response.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_login_response.freezed.dart';
part 'member_login_response.g.dart';

/// Response from POST /auth/member/login
@freezed
class MemberLoginResponse with _$MemberLoginResponse {
  const factory MemberLoginResponse({
    required String memberId,
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required bool mustChangePassword,
  }) = _MemberLoginResponse;

  factory MemberLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$MemberLoginResponseFromJson(json);
}
```

### 2.2 Updated AuthState

**File:** `lib/features/auth/domain/auth_state.dart`

Update to include new intermediate states:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'auth_tokens.dart';
import 'member_profile.dart';
import 'sector_info.dart';

part 'auth_state.freezed.dart';

/// Authentication state for the app.
/// Represents all possible authentication states including intermediate states.
@freezed
sealed class AuthState with _$AuthState {
  /// Initial state before checking stored session
  const factory AuthState.initial() = AuthStateInitial;

  /// Loading state during auth operations
  const factory AuthState.loading() = AuthStateLoading;

  /// User is not authenticated
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;

  /// NEW: User authenticated but must change password before proceeding
  const factory AuthState.mustChangePassword({
    required AuthTokens tokens,
    required String memberId,
  }) = AuthStateMustChangePassword;

  /// NEW: Password changed, awaiting PIN setup
  const factory AuthState.pendingPinSetup({
    required AuthTokens tokens,
    required String memberId,
  }) = AuthStatePendingPinSetup;

  /// Fully authenticated with profile loaded
  const factory AuthState.authenticated({
    required AuthTokens tokens,
    required MemberProfile profile,
    required SectorInfo sector,
  }) = AuthStateAuthenticated;

  /// Authentication error occurred
  const factory AuthState.error(String message) = AuthStateError;
}

/// Extension methods for convenient state checking
extension AuthStateX on AuthState {
  bool get isAuthenticated => this is AuthStateAuthenticated;
  bool get isLoading => this is AuthStateLoading;
  bool get needsPasswordChange => this is AuthStateMustChangePassword;
  bool get needsPinSetup => this is AuthStatePendingPinSetup;

  AuthTokens? get tokens => switch (this) {
        AuthStateAuthenticated(:final tokens) => tokens,
        AuthStateMustChangePassword(:final tokens) => tokens,
        AuthStatePendingPinSetup(:final tokens) => tokens,
        _ => null,
      };

  String? get memberId => switch (this) {
        AuthStateAuthenticated(:final profile) => profile.id,
        AuthStateMustChangePassword(:final memberId) => memberId,
        AuthStatePendingPinSetup(:final memberId) => memberId,
        _ => null,
      };
}
```

### 2.3 Updated AuthTokens

**File:** `lib/features/auth/domain/auth_tokens.dart`

Ensure it handles the new response:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);

  /// Create from member login response
  factory AuthTokens.fromMemberLoginResponse({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) {
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .toIso8601String();
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }
}
```

---

## 3. Data Layer Changes

### 3.1 Updated AuthApi

**File:** `lib/features/auth/data/auth_api.dart`

Replace OTP methods with email authentication:

```dart
import 'package:dio/dio.dart';
import '../domain/member_login_response.dart';
import '../domain/auth_tokens.dart';
import '../domain/member_profile.dart';

/// API client for authentication endpoints
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  // ===============================
  // REMOVED METHODS (OTP-based)
  // ===============================
  // - requestOtp(String phone)
  // - verifyOtp(String phone, String code)
  // - checkPhone(String phone)
  // - completeRegistration(CompleteRegistrationRequest request)

  // ===============================
  // NEW: Email + Password Login
  // ===============================

  /// Login with email and password
  /// POST /auth/member/login
  Future<MemberLoginResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/member/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return MemberLoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Change password
  /// POST /auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  // ===============================
  // EXISTING METHODS (keep)
  // ===============================

  /// Get current user profile
  /// GET /members/me
  Future<MemberProfileResponse> getMe() async {
    final response = await _dio.get('/members/me');
    return MemberProfileResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Refresh access token
  /// POST /auth/refresh
  Future<AuthTokens> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthTokens.fromJson(response.data as Map<String, dynamic>);
  }

  /// Legacy PIN login (for existing users with PIN setup)
  /// POST /auth/login
  Future<LoginResponse> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'phone': phone,
        'pin': pin,
      },
    );
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
```

### 3.2 Updated AuthRepository

**File:** `lib/features/auth/data/auth_repository.dart`

```dart
import '../domain/member_login_response.dart';
import '../domain/auth_tokens.dart';
import '../../shared/utils/result.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _api;

  AuthRepository(this._api);

  // ===============================
  // NEW: Email Authentication
  // ===============================

  /// Login with email and password
  Future<Result<MemberLoginResponse>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return Result.tryAsync(() => _api.loginWithEmail(
          email: email,
          password: password,
        ));
  }

  /// Change password
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return Result.tryAsync(() => _api.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ));
  }

  // ===============================
  // EXISTING METHODS (keep)
  // ===============================

  /// Get current user profile
  Future<Result<MemberProfileResponse>> getMe() async {
    return Result.tryAsync(() => _api.getMe());
  }

  /// Refresh access token
  Future<Result<AuthTokens>> refreshToken(String refreshToken) async {
    return Result.tryAsync(() => _api.refreshToken(refreshToken));
  }
}
```

### 3.3 Updated SecureStorage

**File:** `lib/features/auth/data/secure_storage.dart`

Update to store email instead of phone:

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_tokens.dart';
import '../domain/member_profile.dart';

/// Keys for secure storage
class _StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userProfile = 'user_profile';
  static const email = 'user_email';  // CHANGED: was phone_number
  static const biometricPin = 'biometric_pin';
  static const biometricEnabled = 'biometric_enabled';
  static const pin = 'user_pin';
}

/// Secure storage service for auth credentials
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // ===============================
  // Token Storage
  // ===============================

  Future<void> saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _StorageKeys.accessToken, value: tokens.accessToken),
      _storage.write(key: _StorageKeys.refreshToken, value: tokens.refreshToken),
    ]);
  }

  Future<AuthTokens?> getTokens() async {
    final accessToken = await _storage.read(key: _StorageKeys.accessToken);
    final refreshToken = await _storage.read(key: _StorageKeys.refreshToken);

    if (accessToken == null || refreshToken == null) return null;

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _StorageKeys.accessToken),
      _storage.delete(key: _StorageKeys.refreshToken),
    ]);
  }

  // ===============================
  // Profile Storage
  // ===============================

  Future<void> saveProfile(MemberProfile profile) async {
    await _storage.write(
      key: _StorageKeys.userProfile,
      value: jsonEncode(profile.toJson()),
    );
  }

  Future<MemberProfile?> getProfile() async {
    final json = await _storage.read(key: _StorageKeys.userProfile);
    if (json == null) return null;
    return MemberProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> clearProfile() async {
    await _storage.delete(key: _StorageKeys.userProfile);
  }

  // ===============================
  // Email Storage (for login convenience)
  // ===============================

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _StorageKeys.email, value: email);
  }

  Future<String?> getEmail() async {
    return _storage.read(key: _StorageKeys.email);
  }

  // ===============================
  // PIN Storage
  // ===============================

  Future<void> savePin(String pin) async {
    await _storage.write(key: _StorageKeys.pin, value: pin);
  }

  Future<String?> getPin() async {
    return _storage.read(key: _StorageKeys.pin);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _StorageKeys.pin);
  }

  // ===============================
  // Biometric Storage
  // ===============================

  Future<void> enableBiometric(String pin) async {
    await Future.wait([
      _storage.write(key: _StorageKeys.biometricPin, value: pin),
      _storage.write(key: _StorageKeys.biometricEnabled, value: 'true'),
    ]);
  }

  Future<void> disableBiometric() async {
    await Future.wait([
      _storage.delete(key: _StorageKeys.biometricPin),
      _storage.write(key: _StorageKeys.biometricEnabled, value: 'false'),
    ]);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _StorageKeys.biometricEnabled);
    return value == 'true';
  }

  Future<String?> getBiometricPin() async {
    return _storage.read(key: _StorageKeys.biometricPin);
  }

  // ===============================
  // Session Management
  // ===============================

  /// Clear session data (keeps email and biometric prefs)
  Future<void> clearSession() async {
    await Future.wait([
      clearTokens(),
      clearProfile(),
    ]);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

---

## 4. Provider Layer Changes

### 4.1 Updated AuthNotifier

**File:** `lib/features/auth/providers/auth_providers.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/auth_state.dart';
import '../domain/auth_tokens.dart';
import '../domain/member_login_response.dart';
import '../data/auth_repository.dart';
import '../data/secure_storage.dart';
import '../../shared/utils/result.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late final AuthRepository _repository;
  late final SecureStorageService _storage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);

    // Check for existing session on startup
    _checkExistingSession();

    return const AuthState.initial();
  }

  // ===============================
  // Session Management
  // ===============================

  Future<void> _checkExistingSession() async {
    final tokens = await _storage.getTokens();
    final profile = await _storage.getProfile();

    if (tokens == null || profile == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    // Validate session by calling /members/me
    final result = await _repository.getMe();

    state = result.when(
      success: (response) => AuthState.authenticated(
        tokens: tokens,
        profile: response.member,
        sector: response.sector,
      ),
      failure: (_) {
        _storage.clearSession();
        return const AuthState.unauthenticated();
      },
    );
  }

  // ===============================
  // NEW: Email + Password Login
  // ===============================

  /// Login with email and password
  Future<Result<MemberLoginResponse>> loginWithEmail(
    String email,
    String password,
  ) async {
    state = const AuthState.loading();

    final result = await _repository.loginWithEmail(
      email: email,
      password: password,
    );

    result.when(
      success: (response) async {
        // Save email for future login convenience
        await _storage.saveEmail(email);

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
        state = AuthState.error(error.displayMessage);
      },
    );

    return result;
  }

  // ===============================
  // NEW: Change Password
  // ===============================

  /// Change password (for first-time login)
  Future<Result<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final currentState = state;
    if (currentState is! AuthStateMustChangePassword) {
      return Result.failure(AppError.invalidState('Must be in password change state'));
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
        // Stay in mustChangePassword state, show error
        state = AuthState.error(error.displayMessage);
        // Restore previous state after showing error
        Future.delayed(const Duration(seconds: 2), () {
          state = currentState;
        });
      },
    );

    return result;
  }

  // ===============================
  // PIN Setup Completion
  // ===============================

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

  /// Fetch profile and set authenticated state
  Future<void> _fetchAndSetProfile(AuthTokens tokens) async {
    final result = await _repository.getMe();

    state = result.when(
      success: (response) {
        // Save profile
        _storage.saveProfile(response.member);

        return AuthState.authenticated(
          tokens: tokens,
          profile: response.member,
          sector: response.sector,
        );
      },
      failure: (error) => AuthState.error(error.displayMessage),
    );
  }

  // ===============================
  // Logout
  // ===============================

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState.unauthenticated();
  }

  // ===============================
  // REMOVED METHODS (OTP-based)
  // ===============================
  // - requestOtp(String phone)
  // - verifyOtp(String phone, String code)
  // - completeRegistration(...)

  // ===============================
  // KEEP: Token Refresh
  // ===============================

  Future<Result<AuthTokens>> refreshToken() async {
    final currentTokens = await _storage.getTokens();
    if (currentTokens == null) {
      return Result.failure(AppError.unauthorized('No tokens found'));
    }

    final result = await _repository.refreshToken(currentTokens.refreshToken);

    result.when(
      success: (newTokens) async {
        await _storage.saveTokens(newTokens);

        // Update state if authenticated
        final currentState = state;
        if (currentState is AuthStateAuthenticated) {
          state = currentState.copyWith(tokens: newTokens);
        }
      },
      failure: (_) {
        // Refresh failed, logout
        logout();
      },
    );

    return result;
  }
}

// ===============================
// Convenience Providers
// ===============================

@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
}

@riverpod
MemberProfile? currentProfile(CurrentProfileRef ref) {
  final state = ref.watch(authNotifierProvider);
  if (state is AuthStateAuthenticated) {
    return state.profile;
  }
  return null;
}

@riverpod
String? accessToken(AccessTokenRef ref) {
  return ref.watch(authNotifierProvider).tokens?.accessToken;
}

@riverpod
Future<String?> storedEmail(StoredEmailRef ref) {
  return ref.watch(secureStorageProvider).getEmail();
}
```

---

## 5. Presentation Layer

### 5.1 New EmailLoginPage

**New File:** `lib/features/auth/presentation/pages/email_login_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/theme/spacing.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/email_input_field.dart';
import '../widgets/password_input_field.dart';

/// Login page with email and password
class EmailLoginPage extends ConsumerStatefulWidget {
  const EmailLoginPage({super.key});

  @override
  ConsumerState<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends ConsumerState<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final email = await ref.read(storedEmailProvider.future);
    if (email != null && mounted) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final result = await authNotifier.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.when(
      success: (_) {
        // Navigation handled by router based on auth state
      },
      failure: (error) {
        setState(() {
          _errorText = error.displayMessage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: l10n.loginTitle,
      subtitle: l10n.loginWithEmailSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            EmailInputField(
              controller: _emailController,
              enabled: !_isLoading,
            ),
            const SizedBox(height: Spacing.md),

            // Password field
            PasswordInputField(
              controller: _passwordController,
              enabled: !_isLoading,
              labelText: l10n.passwordLabel,
            ),

            // Error message
            if (_errorText != null) ...[
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: Spacing.xl),

            // Login button
            LoadingButton(
              label: l10n.loginButton,
              onPressed: _login,
              isLoading: _isLoading,
            ),

            const SizedBox(height: Spacing.lg),

            // Info about web registration
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.noAccountQuestion,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.registerOnWebInstruction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.2 New ChangePasswordPage

**New File:** `lib/features/auth/presentation/pages/change_password_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/theme/spacing.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/password_input_field.dart';

/// Page for first-time password change after approval
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    final l10n = S.of(context);

    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordTooShort;
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return l10n.passwordNeedsUppercase;
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return l10n.passwordNeedsLowercase;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return l10n.passwordNeedsNumber;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = S.of(context);

    if (value != _newPasswordController.text) {
      return l10n.passwordsMustMatch;
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final result = await authNotifier.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.when(
      success: (_) {
        // Navigation handled by router based on auth state
      },
      failure: (error) {
        setState(() {
          _errorText = error.displayMessage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: l10n.changePasswordTitle,
      subtitle: l10n.changePasswordSubtitle,
      showBackButton: false, // Can't go back from this screen
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current password (the temp password from email)
            PasswordInputField(
              controller: _currentPasswordController,
              enabled: !_isLoading,
              labelText: l10n.currentPasswordLabel,
              helperText: l10n.tempPasswordHelp,
            ),
            const SizedBox(height: Spacing.lg),

            // New password with requirements
            PasswordInputField(
              controller: _newPasswordController,
              enabled: !_isLoading,
              labelText: l10n.newPasswordLabel,
              validator: _validateNewPassword,
            ),
            const SizedBox(height: Spacing.xs),

            // Password requirements info
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              child: Text(
                l10n.passwordRequirements,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Confirm password
            PasswordInputField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              labelText: l10n.confirmPasswordLabel,
              validator: _validateConfirmPassword,
            ),

            // Error message
            if (_errorText != null) ...[
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: Spacing.xl),

            // Submit button
            LoadingButton(
              label: l10n.changePasswordButton,
              onPressed: _changePassword,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.3 New Input Widgets

**New File:** `lib/features/auth/presentation/widgets/email_input_field.dart`

```dart
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Email input field with validation
class EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;

  const EmailInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.emailLabel,
        prefixIcon: const Icon(Icons.email_outlined),
        hintText: 'example@email.com',
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return l10n.emailRequired;
            }
            if (!EmailValidator.validate(value)) {
              return l10n.invalidEmail;
            }
            return null;
          },
    );
  }
}
```

**New File:** `lib/features/auth/presentation/widgets/password_input_field.dart`

```dart
import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Password input field with visibility toggle
class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? labelText;
  final String? helperText;
  final String? Function(String?)? validator;

  const PasswordInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.labelText,
    this.helperText,
    this.validator,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.labelText ?? l10n.passwordLabel,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return l10n.passwordRequired;
            }
            return null;
          },
    );
  }
}
```

### 5.4 Updated PinSetupPage

**File:** `lib/features/auth/presentation/pages/pin_setup_page.dart`

Simplify to only handle PIN setup after password authentication:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/services/biometric_service.dart';
import '../../../../shared/theme/spacing.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/pin_input.dart';

/// Page for setting up PIN after password authentication
class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  String? _firstPin;
  bool _isConfirming = false;
  String? _errorText;
  bool _isProcessing = false;

  void _onPinEntered(String pin) async {
    if (_isProcessing) return;

    if (!_isConfirming) {
      // First entry - store and ask for confirmation
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
        _errorText = null;
      });
      return;
    }

    // Second entry - verify match
    if (pin != _firstPin) {
      setState(() {
        _firstPin = null;
        _isConfirming = false;
        _errorText = S.of(context).pinsMustMatch;
      });
      return;
    }

    // PINs match - complete setup
    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    // Complete PIN setup
    await ref.read(authNotifierProvider.notifier).completePinSetup(pin);

    if (!mounted) return;

    // Offer biometric setup
    await _offerBiometricSetup(pin);

    // Navigation will be handled by router
  }

  Future<void> _offerBiometricSetup(String pin) async {
    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isBiometricAvailable();

    if (!isAvailable || !mounted) return;

    final biometricType = await biometricService.getBiometricDescription();
    final l10n = S.of(context);

    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.enableBiometricTitle),
        content: Text(l10n.enableBiometricMessage(biometricType)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.enable),
          ),
        ],
      ),
    );

    if (shouldEnable == true) {
      // Verify biometric before enabling
      final result = await biometricService.authenticate();

      if (result is BiometricResultSuccess) {
        await ref.read(secureStorageProvider).enableBiometric(pin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: _isConfirming ? l10n.confirmPinTitle : l10n.setupPinTitle,
      subtitle: _isConfirming ? l10n.confirmPinSubtitle : l10n.setupPinSubtitle,
      showBackButton: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // PIN Input
          PinInput(
            onComplete: _onPinEntered,
            enabled: !_isProcessing,
          ),

          // Error message
          if (_errorText != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              _errorText!,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],

          // Reset button (when confirming)
          if (_isConfirming) ...[
            const SizedBox(height: Spacing.lg),
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      setState(() {
                        _firstPin = null;
                        _isConfirming = false;
                        _errorText = null;
                      });
                    },
              child: Text(l10n.startOver),
            ),
          ],

          // Processing indicator
          if (_isProcessing) ...[
            const SizedBox(height: Spacing.lg),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
```

---

## 6. Router Changes

### 6.1 Updated AppRouter

**File:** `lib/routing/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/pages/email_login_page.dart';
import '../features/auth/presentation/pages/change_password_page.dart';
import '../features/auth/presentation/pages/pin_setup_page.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/home/presentation/pages/home_page.dart';
// ... other imports

part 'app_router.g.dart';

/// Routes that don't require authentication
const _publicRoutes = {'/auth/login'};

/// Routes for authentication flow
const _authFlowRoutes = {
  '/auth/login',
  '/auth/change-password',
  '/auth/pin-setup',
};

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.matchedLocation;

      // Handle redirects based on auth state
      return switch (authState) {
        // Fully authenticated - redirect to home if on auth routes
        AuthStateAuthenticated() when _authFlowRoutes.contains(path) => '/',

        // Must change password - force to password change screen
        AuthStateMustChangePassword() when path != '/auth/change-password' =>
          '/auth/change-password',

        // Pending PIN setup - force to PIN setup screen
        AuthStatePendingPinSetup() when path != '/auth/pin-setup' =>
          '/auth/pin-setup',

        // Not authenticated - redirect to login if not on public route
        AuthStateUnauthenticated() when !_publicRoutes.contains(path) =>
          '/auth/login',

        // Initial/Loading - allow current route
        AuthStateInitial() => null,
        AuthStateLoading() => null,

        // Error state - redirect to login
        AuthStateError() when !_publicRoutes.contains(path) => '/auth/login',

        // No redirect needed
        _ => null,
      };
    },
    routes: [
      // ===============================
      // Auth Routes
      // ===============================
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const EmailLoginPage(),
      ),
      GoRoute(
        path: '/auth/change-password',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/auth/pin-setup',
        name: 'pinSetup',
        builder: (context, state) => const PinSetupPage(),
      ),

      // ===============================
      // App Shell (Protected Routes)
      // ===============================
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/issues',
            name: 'issues',
            builder: (context, state) => const IssuesPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'issueDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return IssueDetailPage(issueId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/report',
            name: 'report',
            builder: (context, state) => const ReportIssuePage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // ===============================
      // REMOVED ROUTES (OTP-based)
      // ===============================
      // - /auth/phone
      // - /auth/otp
      // - /auth/register
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
}
```

---

## 7. Localization

### 7.1 New Strings

**File:** `lib/l10n/app_en.arb`

Add new localization strings:

```json
{
  "loginTitle": "Welcome Back",
  "loginWithEmailSubtitle": "Enter your email and password to continue",
  "emailLabel": "Email Address",
  "emailRequired": "Email is required",
  "invalidEmail": "Please enter a valid email address",
  "passwordLabel": "Password",
  "passwordRequired": "Password is required",
  "loginButton": "Log In",

  "noAccountQuestion": "Don't have an account?",
  "registerOnWebInstruction": "Register at munserv.app to join your community",

  "changePasswordTitle": "Change Your Password",
  "changePasswordSubtitle": "Please set a new secure password to continue",
  "currentPasswordLabel": "Current Password",
  "tempPasswordHelp": "Enter the temporary password from your welcome email",
  "newPasswordLabel": "New Password",
  "confirmPasswordLabel": "Confirm New Password",
  "changePasswordButton": "Change Password",

  "passwordTooShort": "Password must be at least 8 characters",
  "passwordNeedsUppercase": "Password must contain at least one uppercase letter",
  "passwordNeedsLowercase": "Password must contain at least one lowercase letter",
  "passwordNeedsNumber": "Password must contain at least one number",
  "passwordsMustMatch": "Passwords do not match",
  "passwordRequirements": "At least 8 characters, with uppercase, lowercase, and numbers",

  "setupPinTitle": "Set Up Your PIN",
  "setupPinSubtitle": "Create a 4-digit PIN for quick access",
  "confirmPinTitle": "Confirm Your PIN",
  "confirmPinSubtitle": "Enter your PIN again to confirm",
  "pinsMustMatch": "PINs don't match. Please try again.",
  "startOver": "Start Over",

  "enableBiometricTitle": "Enable Biometric Login",
  "enableBiometricMessage": "Would you like to use {biometricType} for faster login?",
  "@enableBiometricMessage": {
    "placeholders": {
      "biometricType": {"type": "String"}
    }
  },
  "notNow": "Not Now",
  "enable": "Enable"
}
```

---

## 8. Testing Requirements

### 8.1 Unit Tests

**File:** `test/features/auth/domain/member_login_response_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv/features/auth/domain/member_login_response.dart';

void main() {
  group('MemberLoginResponse', () {
    test('should deserialize from JSON', () {
      final json = {
        'memberId': '123',
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresIn': 900,
        'mustChangePassword': true,
      };

      final response = MemberLoginResponse.fromJson(json);

      expect(response.memberId, '123');
      expect(response.accessToken, 'access-token');
      expect(response.refreshToken, 'refresh-token');
      expect(response.expiresIn, 900);
      expect(response.mustChangePassword, true);
    });
  });
}
```

**File:** `test/features/auth/providers/auth_providers_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv/features/auth/domain/auth_state.dart';
import 'package:munserv/features/auth/providers/auth_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('AuthNotifier', () {
    late MockAuthRepository mockRepository;
    late MockSecureStorageService mockStorage;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAuthRepository();
      mockStorage = MockSecureStorageService();
      // Setup container with overrides
    });

    test('loginWithEmail sets mustChangePassword state when required', () async {
      when(() => mockRepository.loginWithEmail(any(), any()))
          .thenAnswer((_) async => Result.success(MemberLoginResponse(
                memberId: '123',
                accessToken: 'token',
                refreshToken: 'refresh',
                expiresIn: 900,
                mustChangePassword: true,
              )));

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.loginWithEmail('test@example.com', 'password');

      expect(
        container.read(authNotifierProvider),
        isA<AuthStateMustChangePassword>(),
      );
    });

    test('changePassword transitions to pendingPinSetup', () async {
      // Setup initial state as mustChangePassword
      // Call changePassword
      // Verify state transitions to pendingPinSetup
    });
  });
}
```

### 8.2 Widget Tests

**File:** `test/features/auth/presentation/pages/email_login_page_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv/features/auth/presentation/pages/email_login_page.dart';

void main() {
  group('EmailLoginPage', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EmailLoginPage(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(/* ... */);

      await tester.enterText(find.byType(TextFormField).first, 'invalid');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });
  });
}
```

---

## 9. Implementation Checklist

Use this checklist with `/dev-cycle` for implementation:

### Domain Layer
- [ ] Create `member_login_response.dart` with freezed
- [ ] Update `auth_state.dart` - add mustChangePassword, pendingPinSetup states
- [ ] Run `dart run build_runner build` to generate code

### Data Layer
- [ ] Update `auth_api.dart` - remove OTP methods, add loginWithEmail, changePassword
- [ ] Update `auth_repository.dart` - update methods
- [ ] Update `secure_storage.dart` - replace phone with email storage

### Provider Layer
- [ ] Update `auth_providers.dart` - implement new login flow
- [ ] Run `dart run build_runner build`
- [ ] Write unit tests for AuthNotifier

### Presentation Layer
- [ ] Create `email_input_field.dart`
- [ ] Create `password_input_field.dart`
- [ ] Create `email_login_page.dart`
- [ ] Create `change_password_page.dart`
- [ ] Update `pin_setup_page.dart` - simplify for post-password flow
- [ ] Write widget tests

### Navigation
- [ ] Update `app_router.dart` - new routes and redirects
- [ ] Run `dart run build_runner build`

### Localization
- [ ] Add new strings to `app_en.arb`
- [ ] Run `flutter gen-l10n`

### Cleanup
- [ ] Delete `phone_entry_page.dart`
- [ ] Delete `otp_verify_page.dart`
- [ ] Delete `registration_page.dart`
- [ ] Delete `otp_input_field.dart`
- [ ] Delete `phone_input_field.dart`
- [ ] Delete `otp_request.dart`
- [ ] Delete `otp_verify_result.dart`
- [ ] Delete `check_phone_response.dart`
- [ ] Delete related tests
- [ ] Update barrel files (pages.dart, etc.)

### Testing
- [ ] Run all existing tests - fix any failures
- [ ] Write tests for new components
- [ ] Manual testing of full flow

---

## 10. API Contract Reference

### Authentication Endpoints (Mobile)

```
POST /api/v1/auth/member/login
Request: { email: string, password: string }
Response: {
  memberId: string,
  accessToken: string,
  refreshToken: string,
  expiresIn: number,
  mustChangePassword: boolean
}
Errors:
  - 401: Invalid credentials
  - 403: Account pending approval or suspended

POST /api/v1/auth/change-password
Headers: Authorization: Bearer <accessToken>
Request: { currentPassword: string, newPassword: string }
Response: { message: string }
Errors:
  - 400: Password validation failed
  - 401: Wrong current password

POST /api/v1/auth/refresh
Request: { refreshToken: string }
Response: { accessToken: string, refreshToken: string, expiresIn: number }
Errors:
  - 401: Invalid refresh token
```

---

## 11. Dependencies

Add to `pubspec.yaml` if not present:

```yaml
dependencies:
  email_validator: ^2.1.17  # For email validation
```

Run:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

*Document ready for `/dev-cycle` implementation. Ensure backend phase is complete before starting.*
