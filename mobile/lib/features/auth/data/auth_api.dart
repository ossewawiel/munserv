import 'package:dio/dio.dart';

import '../domain/login_request.dart';
import '../domain/otp_request.dart';
import '../domain/otp_verify_result.dart';
import '../domain/registration_request.dart';

/// API client for authentication endpoints
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// Request OTP for phone number
  /// POST /auth/register
  Future<OtpRequestResponse> requestOtp(OtpRequest request) async {
    final response = await _dio.post(
      '/auth/register',
      data: request.toJson(),
    );
    return OtpRequestResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify OTP code
  /// POST /auth/verify-otp
  Future<OtpVerifyResult> verifyOtp(OtpVerifyRequest request) async {
    final response = await _dio.post(
      '/auth/verify-otp',
      data: request.toJson(),
    );
    return OtpVerifyResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Complete registration for new user
  /// POST /auth/complete-registration
  Future<AuthResponse> completeRegistration({
    required String tempToken,
    required RegistrationRequest request,
  }) async {
    final response = await _dio.post(
      '/auth/complete-registration',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $tempToken'},
      ),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Login with phone and PIN
  /// POST /auth/login
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Refresh access token
  /// POST /auth/refresh
  Future<AuthTokens> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data as Map<String, dynamic>;
    return AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
  }
}
