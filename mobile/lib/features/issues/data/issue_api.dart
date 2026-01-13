import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../shared/models/issue.dart';
import '../../../shared/models/issue_type.dart';
import '../domain/domain.dart';

/// API client for issue endpoints.
/// All endpoints require Authorization header (handled by Dio interceptor).
/// Updated to work with Spring Boot backend (two-step photo upload).
class IssueApi {
  final Dio _dio;

  IssueApi(this._dio);

  /// List issues with filtering and pagination.
  /// GET /issues?sectorId={sectorId}&state={state}&type={type}&page={page}&limit={limit}&sortBy={sortBy}
  Future<PaginatedIssueSummaries> getIssues(IssueFilter filter) async {
    final response = await _dio.get(
      '/issues',
      queryParameters: filter.toQueryParameters(),
    );
    return PaginatedIssueSummaries.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Get issue details by ID.
  /// GET /issues/{issueId}
  Future<IssueDetail> getIssue(String issueId) async {
    final response = await _dio.get('/issues/$issueId');
    return IssueDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get issues reported by the current user.
  /// GET /issues/mine?page={page}&limit={limit}
  Future<PaginatedIssueSummaries> getMyIssues({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/issues/mine',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return PaginatedIssueSummaries.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Report a new issue with photos (two-step process for backend).
  /// Step 1: POST /issues (JSON) - Create issue
  /// Step 2: POST /issues/{id}/photos (multipart) - Upload each photo
  Future<ReportIssueResponse> reportIssue({
    required ReportIssueRequest request,
    required List<String> photoPaths,
  }) async {
    // Step 1: Create issue without photos (JSON request)
    final createResponse = await _dio.post(
      '/issues',
      data: {
        'type': _issueTypeToApiString(request.type),
        'latitude': request.location.latitude,
        'longitude': request.location.longitude,
        'sectorId': request.sectorId,
        if (request.description != null) 'description': request.description,
      },
    );

    final issueData = createResponse.data as Map<String, dynamic>;
    final issueId = issueData['id'] as String;
    final List<String> uploadedPhotoUrls = [];

    // Step 2: Upload each photo separately
    for (final path in photoPaths) {
      try {
        final fileName = path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        final mimeType = _getMimeType(extension);

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            path,
            filename: fileName,
            contentType: mimeType,
          ),
        });

        final photoResponse = await _dio.post(
          '/issues/$issueId/photos',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );

        final photoData = photoResponse.data as Map<String, dynamic>;
        uploadedPhotoUrls.add(photoData['url'] as String);
      } catch (e) {
        // Log error but continue with other photos
        debugPrint('Failed to upload photo $path: $e');
      }
    }

    // Build response combining issue data and uploaded photos
    return ReportIssueResponse(
      id: issueId,
      type: _issueTypeFromApiString(issueData['type'] as String),
      state: issueData['state'] as String,
      location: request.location,
      heat: issueData['heat'] as int,
      photoUrls: uploadedPhotoUrls,
      createdAt: DateTime.parse(issueData['createdAt'] as String),
    );
  }

  /// Get the full Issue model (for compatibility with existing code).
  /// This is an alias for getIssue that converts to Issue.
  Future<Issue> getIssueFull(String issueId) async {
    final response = await _dio.get('/issues/$issueId');
    return Issue.fromJson(response.data as Map<String, dynamic>);
  }

  /// Convert IssueType enum to backend API string (snake_case)
  String _issueTypeToApiString(IssueType type) {
    return switch (type) {
      IssueType.pothole => 'pothole',
      IssueType.waterLeak => 'water_leak',
      IssueType.sewageLeak => 'sewage_leak',
      IssueType.trafficLight => 'traffic_light',
      IssueType.streetLight => 'street_light',
      IssueType.illegalDumping => 'illegal_dumping',
      IssueType.roadDamage => 'road_damage',
      IssueType.other => 'other',
    };
  }

  /// Convert backend API string to IssueType enum
  IssueType _issueTypeFromApiString(String apiString) {
    return switch (apiString.toLowerCase()) {
      'pothole' => IssueType.pothole,
      'water_leak' => IssueType.waterLeak,
      'sewage_leak' => IssueType.sewageLeak,
      'traffic_light' => IssueType.trafficLight,
      'street_light' => IssueType.streetLight,
      'illegal_dumping' => IssueType.illegalDumping,
      'road_damage' => IssueType.roadDamage,
      'other' => IssueType.other,
      _ => IssueType.other,
    };
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
