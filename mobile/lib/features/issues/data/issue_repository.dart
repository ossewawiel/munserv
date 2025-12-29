import 'package:dio/dio.dart';

import '../../../shared/models/issue.dart';
import '../../../shared/utils/app_error.dart';
import '../../../shared/utils/result.dart';
import '../domain/domain.dart';
import 'issue_api.dart';

/// Repository for issue operations.
/// Wraps IssueApi and returns Result types for error handling.
class IssueRepository {
  final IssueApi _api;

  IssueRepository(this._api);

  /// Get paginated list of issues with filters.
  Future<Result<PaginatedIssueSummaries>> getIssues(IssueFilter filter) async {
    try {
      final response = await _api.getIssues(filter);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get detailed issue by ID.
  Future<Result<IssueDetail>> getIssue(String issueId) async {
    try {
      final response = await _api.getIssue(issueId);
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(AppError.fromDio(e));
    } catch (e) {
      return Result.failure(AppError.unknown(message: e.toString()));
    }
  }

  /// Get full Issue model by ID (for map markers, etc.).
  Future<Result<Issue>> getIssueFull(String issueId) async {
    try {
      final response = await _api.getIssueFull(issueId);
      return Result.success(response);
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
      return Result.success(response);
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
