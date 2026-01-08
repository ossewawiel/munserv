import 'package:dio/dio.dart';

import '../../../shared/models/geo_point.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import '../domain/backend_registration_request.dart';
import '../domain/login_request.dart';
import '../domain/otp_request.dart';
import '../domain/otp_verify_result.dart';
import 'auth_api.dart';
import 'secure_storage.dart';

/// Repository for authentication operations
/// Wraps AuthApi and returns Result types for error handling
/// Updated to work with Spring Boot backend (port 8080)
class AuthRepository {
  final AuthApi _api;
  final SecureStorageService _secureStorage;

  AuthRepository(this._api, this._secureStorage);

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

  /// Verify OTP code and check if user is registered
  /// For backend: OTP verify returns just success, then we check if phone is registered
  Future<Result<OtpVerifyResult>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      // Step 1: Verify OTP
      await _api.verifyOtp(
        OtpVerifyRequest(phoneNumber: phoneNumber, otp: otp),
      );

      // Step 2: Check if phone is registered
      final checkResponse = await _api.checkPhone(phoneNumber);

      if (checkResponse.isRegistered) {
        // Existing user - they need to login with PIN
        return Result.success(const OtpVerifyResult.existingUser(
          tokens: null,
          profile: null,
        ));
      } else {
        // New user - needs registration
        return Result.success(const OtpVerifyResult.newUser(
          tempToken: '', // Backend doesn't use tempToken
        ));
      }
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Complete registration for new user
  /// Backend flow: register -> save tokens -> fetch profile -> fetch sector
  Future<Result<AuthResponse>> completeRegistration({
    required String phoneNumber,
    required String firstName,
    required String surname,
    required String pin,
    required GeoPoint location,
    required String address,
    required String sectorId,
  }) async {
    try {
      // Step 1: Complete registration - get tokens
      final regResponse = await _api.completeRegistration(
        BackendRegistrationRequest(
          phone: phoneNumber,
          firstName: firstName,
          surname: surname,
          pin: pin,
          address: address,
          sectorId: sectorId,
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );

      // Step 2: Save tokens immediately for subsequent requests
      await _secureStorage.saveTokens(regResponse.toAuthTokens());

      // Step 3: Fetch profile with new token
      final profileResponse = await _api.getMe();

      // Step 4: Fetch sector info
      final sectorResponse = await _api.getSector(profileResponse.sectorId);

      // Step 5: Build AuthResponse (existing format for compatibility)
      return Result.success(AuthResponse(
        tokens: regResponse.toAuthTokens(),
        profile: AuthProfile(
          member: profileResponse.toMemberProfile(),
          sector: sectorResponse,
        ),
      ));
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Login with phone and PIN
  /// Backend flow: login -> save tokens -> fetch profile -> fetch sector
  Future<Result<AuthResponse>> login(String phoneNumber, String pin) async {
    try {
      // Step 1: Login - get tokens
      final loginResponse = await _api.login(
        LoginRequest(phoneNumber: phoneNumber, pin: pin),
      );

      // Step 2: Save tokens immediately for subsequent requests
      await _secureStorage.saveTokens(loginResponse.toAuthTokens());

      // Step 3: Fetch profile with new token
      final profileResponse = await _api.getMe();

      // Step 4: Fetch sector info
      final sectorResponse = await _api.getSector(profileResponse.sectorId);

      // Step 5: Build AuthResponse (existing format for compatibility)
      return Result.success(AuthResponse(
        tokens: loginResponse.toAuthTokens(),
        profile: AuthProfile(
          member: profileResponse.toMemberProfile(),
          sector: sectorResponse,
        ),
      ));
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

  /// Get sectors list (for registration)
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
}
