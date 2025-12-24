import 'package:dio/dio.dart';

import '../../../shared/models/geo_point.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import '../domain/login_request.dart';
import '../domain/otp_request.dart';
import '../domain/otp_verify_result.dart';
import '../domain/registration_request.dart';
import 'auth_api.dart';

/// Repository for authentication operations
/// Wraps AuthApi and returns Result types for error handling
class AuthRepository {
  final AuthApi _api;

  AuthRepository(this._api);

  /// Request OTP for phone number
  Future<Result<OtpRequestResponse>> requestOtp(String phoneNumber) async {
    try {
      final response = await _api.requestOtp(
        OtpRequest(phoneNumber: phoneNumber),
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Verify OTP code
  Future<Result<OtpVerifyResult>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final response = await _api.verifyOtp(
        OtpVerifyRequest(phoneNumber: phoneNumber, otp: otp),
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Complete registration for new user
  Future<Result<AuthResponse>> completeRegistration({
    required String tempToken,
    required String firstName,
    required String surname,
    required String pin,
    required GeoPoint location,
    required String address,
  }) async {
    try {
      final response = await _api.completeRegistration(
        tempToken: tempToken,
        request: RegistrationRequest(
          firstName: firstName,
          surname: surname,
          pin: pin,
          location: location,
          address: address,
        ),
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Login with phone and PIN
  Future<Result<AuthResponse>> login(String phoneNumber, String pin) async {
    try {
      final response = await _api.login(
        LoginRequest(phoneNumber: phoneNumber, pin: pin),
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Refresh access token
  Future<Result<AuthTokens>> refreshToken(String refreshToken) async {
    try {
      final response = await _api.refreshToken(refreshToken);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }
}
