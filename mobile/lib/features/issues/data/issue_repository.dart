import 'package:dio/dio.dart';

import '../../../shared/models/issue.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import '../../../shared/utils/url_transformer.dart';
import '../domain/domain.dart';
import 'issue_api.dart';

// API URL configuration (same as dio_provider.dart)
const String _apiHost = String.fromEnvironment(
  'API_HOST',
  defaultValue: '10.0.2.2',
);
const String _apiPort = String.fromEnvironment(
  'API_PORT',
  defaultValue: '8080',
);

/// Repository for issue operations.
/// Wraps IssueApi and returns Result types for error handling.
/// Includes in-flight request deduplication to prevent duplicate API calls.
class IssueRepository {
  final IssueApi _api;
  final UrlTransformer _urlTransformer;

  /// Cache for in-flight issue detail requests to prevent duplicate calls
  final Map<String, Future<Result<IssueDetail>>> _inFlightIssueDetailRequests =
      {};

  /// Cache for in-flight full issue requests
  final Map<String, Future<Result<Issue>>> _inFlightIssueFullRequests = {};

  IssueRepository(this._api)
    : _urlTransformer = UrlTransformer(apiHost: _apiHost, apiPort: _apiPort);

  /// Get paginated list of issues with filters.
  Future<Result<PaginatedIssueSummaries>> getIssues(IssueFilter filter) async {
    try {
      final response = await _api.getIssues(filter);
      // Transform thumbnail URLs from localhost to actual API host
      final transformedItems = response.items.map((item) {
        if (item.thumbnailUrl != null) {
          return item.copyWith(
            thumbnailUrl: _urlTransformer.transform(item.thumbnailUrl!),
          );
        }
        return item;
      }).toList();
      return Result.success(response.copyWith(items: transformedItems));
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get detailed issue by ID.
  /// Uses in-flight request deduplication to prevent duplicate API calls
  /// when multiple widgets request the same issue simultaneously.
  Future<Result<IssueDetail>> getIssue(String issueId) async {
    // Return existing in-flight request if one exists
    if (_inFlightIssueDetailRequests.containsKey(issueId)) {
      return _inFlightIssueDetailRequests[issueId]!;
    }

    // Create and cache the request
    final request = _fetchIssueDetail(issueId);
    _inFlightIssueDetailRequests[issueId] = request;

    try {
      return await request;
    } finally {
      // Remove from cache after completion (success or failure)
      _inFlightIssueDetailRequests.remove(issueId);
    }
  }

  /// Internal method to actually fetch the issue detail.
  Future<Result<IssueDetail>> _fetchIssueDetail(String issueId) async {
    try {
      final response = await _api.getIssue(issueId);
      // Transform photo URLs from localhost to actual API host
      final transformedResponse = response.copyWith(
        photoUrls: _urlTransformer.transformList(response.photoUrls),
      );
      return Result.success(transformedResponse);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get full Issue model by ID (for map markers, etc.).
  /// Uses in-flight request deduplication to prevent duplicate API calls.
  Future<Result<Issue>> getIssueFull(String issueId) async {
    // Return existing in-flight request if one exists
    if (_inFlightIssueFullRequests.containsKey(issueId)) {
      return _inFlightIssueFullRequests[issueId]!;
    }

    // Create and cache the request
    final request = _fetchIssueFull(issueId);
    _inFlightIssueFullRequests[issueId] = request;

    try {
      return await request;
    } finally {
      // Remove from cache after completion (success or failure)
      _inFlightIssueFullRequests.remove(issueId);
    }
  }

  /// Internal method to actually fetch the full issue.
  Future<Result<Issue>> _fetchIssueFull(String issueId) async {
    try {
      final response = await _api.getIssueFull(issueId);
      // Transform photo URLs from localhost to actual API host
      final transformedResponse = response.copyWith(
        photoUrls: _urlTransformer.transformList(response.photoUrls),
      );
      return Result.success(transformedResponse);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get issues reported by the current user.
  Future<Result<PaginatedIssueSummaries>> getMyIssues({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getMyIssues(page: page, limit: limit);
      // Transform thumbnail URLs from localhost to actual API host
      final transformedItems = response.items.map((item) {
        if (item.thumbnailUrl != null) {
          return item.copyWith(
            thumbnailUrl: _urlTransformer.transform(item.thumbnailUrl!),
          );
        }
        return item;
      }).toList();
      return Result.success(response.copyWith(items: transformedItems));
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Report a new issue with photos.
  Future<Result<ReportIssueResponse>> reportIssue({
    required ReportIssueRequest request,
    required List<String> photoPaths,
  }) async {
    try {
      final response = await _api.reportIssue(
        request: request,
        photoPaths: photoPaths,
      );
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }
}
