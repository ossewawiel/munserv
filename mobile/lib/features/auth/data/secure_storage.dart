import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/login_request.dart';

/// Keys for secure storage
abstract class SecureStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userProfile = 'user_profile';
  static const String phoneNumber = 'phone_number';
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
    final refreshToken =
        await _storage.read(key: SecureStorageKeys.refreshToken);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
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
  Future<void> saveProfile(UserProfile profile) async {
    await _storage.write(
      key: SecureStorageKeys.userProfile,
      value: jsonEncode(profile.toJson()),
    );
  }

  /// Get stored user profile
  Future<UserProfile?> getProfile() async {
    final json = await _storage.read(key: SecureStorageKeys.userProfile);
    if (json == null) {
      return null;
    }
    return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
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

  // --- Session Management ---

  /// Check if there's a valid session (has access token)
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
