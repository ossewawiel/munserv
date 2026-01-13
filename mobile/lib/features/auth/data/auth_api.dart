import 'package:dio/dio.dart';

import '../../../shared/models/geo_point.dart';
import '../domain/auth_types.dart';
import '../domain/backend_login_response.dart';
import '../domain/member_login_response.dart';
import '../domain/member_profile_response.dart';

/// API client for authentication endpoints
/// Updated for email + password authentication (Web Registration Flow)
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// Get current member profile
  /// GET /members/me
  /// Requires valid JWT token in Authorization header
  Future<MemberProfileResponse> getMe() async {
    final response = await _dio.get('/members/me');
    return MemberProfileResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
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

  // ===============================
  // Email + Password Authentication
  // ===============================

  /// Login with email and password
  /// POST /auth/member/login
  /// Used for web registration flow where members register via web portal
  Future<MemberLoginResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/member/login',
      data: {'email': email, 'password': password},
    );
    return MemberLoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Change password
  /// POST /auth/change-password
  /// Used when mustChangePassword is true after first login
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
