import 'package:dio/dio.dart';

import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import '../domain/auth_types.dart';
import '../domain/member_login_response.dart';
import '../domain/member_profile_response.dart';
import 'auth_api.dart';
import 'secure_storage.dart';

/// Repository for authentication operations
/// Updated for email + password authentication (Web Registration Flow)
class AuthRepository {
  final AuthApi _api;
  final SecureStorageService _secureStorage;

  AuthRepository(this._api, this._secureStorage);

  /// Refresh access token
  Future<Result<AuthTokens>> refreshToken(String refreshToken) async {
    try {
      final response = await _api.refreshToken(refreshToken);
      final tokens = response.toAuthTokens();

      // Save new tokens
      await _secureStorage.saveTokens(tokens);

      return Result.success(tokens);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get sectors list
  Future<Result<List<SectorInfo>>> getSectors() async {
    try {
      final sectors = await _api.getSectors();
      return Result.success(sectors);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  // ===============================
  // Email Authentication (Web Registration Flow)
  // ===============================

  /// Login with email and password
  /// Used for members who registered via web portal
  Future<Result<MemberLoginResponse>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.loginWithEmail(
        email: email,
        password: password,
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Change password
  /// Used when mustChangePassword is true after first login
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get current user profile
  /// GET /members/me
  Future<Result<MemberProfileResponse>> getMe() async {
    try {
      final response = await _api.getMe();
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }
}
