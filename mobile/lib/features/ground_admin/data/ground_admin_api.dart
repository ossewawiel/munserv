import 'package:dio/dio.dart';

import '../../../shared/models/ground_admin.dart';

/// API client for Ground Admin endpoints.
/// All endpoints require Authorization header (handled by Dio interceptor).
class GroundAdminApi {
  final Dio _dio;

  GroundAdminApi(this._dio);

  /// Get current member's Ground Admin info (if applicable).
  /// GET /members/me/ground-admin
  /// Returns null if not a Ground Admin.
  Future<GroundAdminInfo?> getMyGroundAdminInfo() async {
    final response = await _dio.get('/members/me/ground-admin');
    if (response.data == null) return null;
    return GroundAdminInfo.fromJson(response.data as Map<String, dynamic>);
  }

  /// Apply to become a Ground Admin.
  /// POST /members/me/ground-admin/apply
  Future<GroundAdminApplication> apply() async {
    final response = await _dio.post('/members/me/ground-admin/apply');
    return GroundAdminApplication.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Accept Ground Admin invitation.
  /// POST /members/me/ground-admin/accept
  Future<GroundAdminActionResponse> acceptInvitation(
    String applicationId,
  ) async {
    final response = await _dio.post(
      '/members/me/ground-admin/accept',
      data: {'applicationId': applicationId},
    );
    return GroundAdminActionResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Decline Ground Admin invitation.
  /// POST /members/me/ground-admin/decline
  Future<void> declineInvitation(String applicationId, {String? reason}) async {
    await _dio.post(
      '/members/me/ground-admin/decline',
      data: {
        'applicationId': applicationId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Request to step down from Ground Admin role.
  /// POST /members/me/ground-admin/stepdown
  Future<void> stepDown({String? reason}) async {
    await _dio.post(
      '/members/me/ground-admin/stepdown',
      data: {if (reason != null) 'reason': reason},
    );
  }
}
