import 'package:dio/dio.dart';

import '../../../shared/models/geo_point.dart';
import '../domain/backend_login_response.dart';
import '../domain/backend_registration_request.dart';
import '../domain/check_phone_response.dart';
import '../domain/login_request.dart';
import '../domain/member_profile_response.dart';
import '../domain/otp_request.dart';
import '../domain/otp_verify_result.dart';

/// API client for authentication endpoints
/// Updated to work with Spring Boot backend (port 8080)
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// Request OTP for phone number
  /// POST /auth/register
  Future<OtpRequestResponse> requestOtp(OtpRequest request) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'phone': request.phoneNumber},
    );
    return OtpRequestResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify OTP code
  /// POST /auth/verify-otp
  /// Backend returns { message } - we just need success/failure
  Future<void> verifyOtp(OtpVerifyRequest request) async {
    await _dio.post(
      '/auth/verify-otp',
      data: {
        'phone': request.phoneNumber,
        'code': request.otp,
      },
    );
    // Backend returns { message: "OTP verified successfully" }
    // Success is indicated by no exception
  }

  /// Check if phone number is registered
  /// GET /auth/check-phone?phone=...
  Future<CheckPhoneResponse> checkPhone(String phone) async {
    final response = await _dio.get(
      '/auth/check-phone',
      queryParameters: {'phone': phone},
    );
    return CheckPhoneResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Complete registration for new user
  /// POST /auth/complete-registration
  /// Returns flat response: { memberId, accessToken, refreshToken, expiresIn }
  Future<BackendLoginResponse> completeRegistration(
    BackendRegistrationRequest request,
  ) async {
    final response = await _dio.post(
      '/auth/complete-registration',
      data: request.toJson(),
    );
    return BackendLoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Login with phone and PIN
  /// POST /auth/login
  /// Returns flat response: { memberId, accessToken, refreshToken, expiresIn }
  Future<BackendLoginResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'phone': request.phoneNumber,
        'pin': request.pin,
      },
    );
    return BackendLoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get current member profile
  /// GET /members/me
  /// Requires valid JWT token in Authorization header
  Future<MemberProfileResponse> getMe() async {
    final response = await _dio.get('/members/me');
    return MemberProfileResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get sector by ID
  /// GET /sectors/{sectorId}
  Future<SectorInfo> getSector(String sectorId) async {
    final response = await _dio.get('/sectors/$sectorId');
    final data = response.data as Map<String, dynamic>;
    final center = data['center'] as Map<String, dynamic>;
    return SectorInfo(
      id: data['id'] as String,
      name: data['name'] as String,
      center: GeoPoint(
        latitude: (center['latitude'] as num).toDouble(),
        longitude: (center['longitude'] as num).toDouble(),
      ),
    );
  }

  /// Refresh access token
  /// POST /auth/refresh
  /// Returns flat response: { accessToken, refreshToken, expiresIn }
  Future<BackendLoginResponse> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return BackendLoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get all sectors
  /// GET /sectors
  /// Returns paginated list of sectors
  Future<List<SectorInfo>> getSectors() async {
    final response = await _dio.get('/sectors');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items.map((item) {
      final sectorData = item as Map<String, dynamic>;
      final center = sectorData['center'] as Map<String, dynamic>;
      return SectorInfo(
        id: sectorData['id'] as String,
        name: sectorData['name'] as String,
        center: GeoPoint(
          latitude: (center['latitude'] as num).toDouble(),
          longitude: (center['longitude'] as num).toDouble(),
        ),
      );
    }).toList();
  }
}
