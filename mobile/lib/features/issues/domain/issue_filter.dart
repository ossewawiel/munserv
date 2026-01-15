import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/issue_state.dart';
import '../../../shared/models/issue_type.dart';

part 'issue_filter.freezed.dart';
part 'issue_filter.g.dart';

/// Sort options for issue lists.
@JsonEnum(fieldRename: FieldRename.snake)
enum IssueSortBy {
  heat,
  createdAt;

  String get displayName => switch (this) {
    heat => 'Priority',
    createdAt => 'Date',
  };
}

/// Filter and pagination parameters for issue queries.
@freezed
abstract class IssueFilter with _$IssueFilter {
  const IssueFilter._();

  const factory IssueFilter({
    required String sectorId,
    IssueState? state,
    IssueType? type,
    @Default(1) int page,
    @Default(20) int limit,
    @Default(IssueSortBy.heat) IssueSortBy sortBy,
  }) = _IssueFilter;

  /// Converts filter to query parameters map for API calls.
  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'sectorId': sectorId,
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy.name,
    };

    if (state != null) {
      params['state'] = state!.name;
    }
    if (type != null) {
      params['type'] = type!.name;
    }

    return params;
  }

  factory IssueFilter.fromJson(Map<String, dynamic> json) =>
      _$IssueFilterFromJson(json);
}
