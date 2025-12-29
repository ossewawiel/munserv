import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../shared/models/issue.dart';
import '../domain/domain.dart';

/// API client for issue endpoints.
/// All endpoints require Authorization header (handled by Dio interceptor).
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

  /// Report a new issue with photos.
  /// POST /issues (multipart/form-data)
  Future<ReportIssueResponse> reportIssue({
    required ReportIssueRequest request,
    required List<String> photoPaths,
  }) async {
    final formData = FormData.fromMap({
      'type': request.type.name,
      'latitude': request.location.latitude.toString(),
      'longitude': request.location.longitude.toString(),
      if (request.description != null) 'description': request.description,
    });

    // Add photo files
    for (int i = 0; i < photoPaths.length; i++) {
      final path = photoPaths[i];
      final fileName = path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      formData.files.add(
        MapEntry(
          'photos',
          await MultipartFile.fromFile(
            path,
            filename: fileName,
            contentType: mimeType,
          ),
        ),
      );
    }

    final response = await _dio.post(
      '/issues',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    return ReportIssueResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Get the full Issue model (for compatibility with existing code).
  /// This is an alias for getIssue that converts to Issue.
  Future<Issue> getIssueFull(String issueId) async {
    final response = await _dio.get('/issues/$issueId');
    return Issue.fromJson(response.data as Map<String, dynamic>);
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
