import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';
import 'issue_state.dart';
import 'issue_type.dart';

part 'issue.freezed.dart';
part 'issue.g.dart';

@freezed
abstract class Issue with _$Issue {
  const Issue._();

  const factory Issue({
    required String id,
    required IssueType type,
    required IssueState state,
    required GeoPoint location,
    String? address,
    String? description,
    required int heat,
    required List<String> photoUrls,
    required String sectorId,
    required String reporterId,
    required int reportCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Issue;

  bool canTransitionTo(IssueState newState) =>
      state.allowedTransitions.contains(newState);

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
}

@freezed
abstract class IssueSummary with _$IssueSummary {
  const factory IssueSummary({
    required String id,
    required IssueType type,
    required IssueState state,
    required GeoPoint location,
    required int heat,
    required String thumbnailUrl,
    required DateTime createdAt,
  }) = _IssueSummary;

  factory IssueSummary.fromJson(Map<String, dynamic> json) =>
      _$IssueSummaryFromJson(json);
}
