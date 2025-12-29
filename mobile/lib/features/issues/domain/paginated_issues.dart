import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/issue.dart';

part 'paginated_issues.freezed.dart';
part 'paginated_issues.g.dart';

/// Pagination metadata from API responses.
@freezed
abstract class Pagination with _$Pagination {
  const Pagination._();

  const factory Pagination({
    required int page,
    required int limit,
    required int totalItems,
    required int totalPages,
  }) = _Pagination;

  /// Whether there are more pages available.
  bool get hasNextPage => page < totalPages;

  /// Whether there are previous pages.
  bool get hasPreviousPage => page > 1;

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
}

/// Paginated list of issue summaries.
@freezed
abstract class PaginatedIssueSummaries with _$PaginatedIssueSummaries {
  const factory PaginatedIssueSummaries({
    required List<IssueSummary> items,
    required Pagination pagination,
  }) = _PaginatedIssueSummaries;

  factory PaginatedIssueSummaries.fromJson(Map<String, dynamic> json) =>
      _$PaginatedIssueSummariesFromJson(json);
}

/// Paginated list of full issues.
@freezed
abstract class PaginatedIssues with _$PaginatedIssues {
  const factory PaginatedIssues({
    required List<Issue> items,
    required Pagination pagination,
  }) = _PaginatedIssues;

  factory PaginatedIssues.fromJson(Map<String, dynamic> json) =>
      _$PaginatedIssuesFromJson(json);
}
