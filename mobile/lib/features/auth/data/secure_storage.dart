import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_types.dart';

/// Keys for secure storage
abstract class SecureStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userProfile = 'user_profile';
  static const String phoneNumber = 'phone_number';
  static const String email = 'user_email';
  static const String password = 'user_password'; // For quick login
  static const String pin = 'user_pin';
  static const String biometricPin = 'biometric_pin';
  static const String biometricEnabled = 'biometric_enabled';
}

/// Service for secure storage of auth tokens and user data
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // --- Tokens ---

  /// Save auth tokens
  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(
      key: SecureStorageKeys.accessToken,
      value: tokens.accessToken,
    );
    await _storage.write(
      key: SecureStorageKeys.refreshToken,
      value: tokens.refreshToken,
    );
  }

  /// Get stored auth tokens
  Future<AuthTokens?> getTokens() async {
    final accessToken = await _storage.read(key: SecureStorageKeys.accessToken);
    final refreshToken = await _storage.read(
      key: SecureStorageKeys.refreshToken,
    );

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: SecureStorageKeys.accessToken);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: SecureStorageKeys.refreshToken);
  }

  /// Clear stored tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
  }

  // --- Profile ---

  /// Save user profile
  Future<void> saveProfile(MemberProfile profile) async {
    await _storage.write(
      key: SecureStorageKeys.userProfile,
      value: jsonEncode(profile.toJson()),
    );
  }

  /// Get stored user profile
  Future<MemberProfile?> getProfile() async {
    final json = await _storage.read(key: SecureStorageKeys.userProfile);
    if (json == null) {
      return null;
    }
    return MemberProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Clear stored profile
  Future<void> clearProfile() async {
    await _storage.delete(key: SecureStorageKeys.userProfile);
  }

  // --- Phone Number ---

  /// Save phone number (for login convenience)
  Future<void> savePhoneNumber(String phoneNumber) async {
    await _storage.write(
      key: SecureStorageKeys.phoneNumber,
      value: phoneNumber,
    );
  }

  /// Get stored phone number
  Future<String?> getPhoneNumber() async {
    return _storage.read(key: SecureStorageKeys.phoneNumber);
  }

  // --- Email Storage (for web registration flow) ---

  /// Save email address (for login convenience)
  Future<void> saveEmail(String email) async {
    await _storage.write(key: SecureStorageKeys.email, value: email);
  }

  /// Get stored email
  Future<String?> getEmail() async {
    return _storage.read(key: SecureStorageKeys.email);
  }

  // --- Password Storage (for quick login) ---

  /// Save password for quick login
  /// Note: Password is stored encrypted in secure storage
  Future<void> savePassword(String password) async {
    await _storage.write(key: SecureStorageKeys.password, value: password);
  }

  /// Get stored password
  Future<String?> getPassword() async {
    return _storage.read(key: SecureStorageKeys.password);
  }

  /// Clear stored password
  Future<void> clearPassword() async {
    await _storage.delete(key: SecureStorageKeys.password);
  }

  // --- PIN Storage ---

  /// Save PIN for quick access
  Future<void> savePin(String pin) async {
    await _storage.write(key: SecureStorageKeys.pin, value: pin);
  }

  /// Get stored PIN
  Future<String?> getPin() async {
    return _storage.read(key: SecureStorageKeys.pin);
  }

  /// Clear stored PIN
  Future<void> clearPin() async {
    await _storage.delete(key: SecureStorageKeys.pin);
  }

  // --- Session Management ---

  /// Check if there's a valid session (has access token)
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Clear all stored data (full reset)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Clear session data but keep phone number and biometric settings (logout)
  Future<void> clearSession() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
    // Keep: phoneNumber, biometricPin, biometricEnabled
  }

  // --- Quick Login ---

  /// Check if user has all credentials needed for quick login (PIN/biometric)
  /// Returns true if email, password, and PIN are all stored
  Future<bool> hasQuickLoginCredentials() async {
    final email = await getEmail();
    final password = await getPassword();
    final pin = await getPin();
    return email != null && password != null && pin != null;
  }

  /// Clear quick login data (for switching accounts)
  /// Keeps email for convenience when re-logging in
  Future<void> clearQuickLoginData() async {
    await _storage.delete(key: SecureStorageKeys.password);
    await _storage.delete(key: SecureStorageKeys.pin);
    await _storage.delete(key: SecureStorageKeys.biometricPin);
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
    // Note: Email is NOT deleted so user can easily re-login
  }

  // --- Biometric Authentication ---

  /// Enable biometric login by storing the PIN
  Future<void> enableBiometric(String pin) async {
    await _storage.write(key: SecureStorageKeys.biometricPin, value: pin);
    await _storage.write(
      key: SecureStorageKeys.biometricEnabled,
      value: 'true',
    );
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await _storage.delete(key: SecureStorageKeys.biometricPin);
    await _storage.write(
      key: SecureStorageKeys.biometricEnabled,
      value: 'false',
    );
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(
      key: SecureStorageKeys.biometricEnabled,
    );
    return enabled == 'true';
  }

  /// Get stored PIN for biometric login
  /// Only returns if biometric is enabled
  Future<String?> getBiometricPin() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return null;
    return _storage.read(key: SecureStorageKeys.biometricPin);
  }
}
