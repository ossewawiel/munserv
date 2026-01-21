import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../shared/models/notification_settings.dart';
import '../../../shared/models/verification.dart';

/// API client for verification endpoints.
/// All endpoints require Authorization header (handled by Dio interceptor).
class VerificationApi {
  final Dio _dio;

  VerificationApi(this._dio);

  /// Get pending verifications for current Ground Admin.
  /// GET /members/me/pending-verifications
  Future<List<PendingVerification>> getPendingVerifications() async {
    final response = await _dio.get('/members/me/pending-verifications');
    final items = (response.data['items'] as List?) ?? [];
    return items
        .map((e) => PendingVerification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Submit verification result.
  /// POST /issues/{issueId}/verify
  Future<IssueVerification> submitVerification({
    required String issueId,
    required String verificationId,
    required String result,
    String? reason,
    String? note,
    File? photo,
  }) async {
    String? photoId;

    // Upload photo first if provided
    if (photo != null) {
      photoId = await _uploadPhoto(issueId, photo);
    }

    final response = await _dio.post(
      '/issues/$issueId/verify',
      data: {
        'verificationId': verificationId,
        'result': result,
        if (reason != null) 'reason': reason,
        if (note != null) 'note': note,
        if (photoId != null) 'photoId': photoId,
      },
    );
    return IssueVerification.fromJson(response.data as Map<String, dynamic>);
  }

  /// Upload a verification photo.
  /// POST /issues/{issueId}/photos
  Future<String> _uploadPhoto(String issueId, File photo) async {
    final fileName = photo.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final mimeType = _getMimeType(extension);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        photo.path,
        filename: fileName,
        contentType: mimeType,
      ),
    });

    final response = await _dio.post(
      '/issues/$issueId/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data['id'] as String;
  }

  /// Get verification history for an issue.
  /// GET /issues/{issueId}/verifications
  Future<List<IssueVerification>> getVerificationHistory(String issueId) async {
    final response = await _dio.get('/issues/$issueId/verifications');
    final items = (response.data['items'] as List?) ?? [];
    return items
        .map((e) => IssueVerification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get notification settings.
  /// GET /members/me/notification-settings
  Future<NotificationSettings> getNotificationSettings() async {
    final response = await _dio.get('/members/me/notification-settings');
    return NotificationSettings.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update notification settings.
  /// PATCH /members/me/notification-settings
  Future<NotificationSettings> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    final response = await _dio.patch(
      '/members/me/notification-settings',
      data: settings.toJson(),
    );
    return NotificationSettings.fromJson(response.data as Map<String, dynamic>);
  }

  MediaType _getMimeType(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      _ => MediaType('application', 'octet-stream'),
    };
  }
}
