import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/geo_point.dart';
import '../../../shared/models/issue_state.dart';

part 'state_history.freezed.dart';
part 'state_history.g.dart';

/// A single entry in an issue's state change history.
@freezed
abstract class StateHistoryEntry with _$StateHistoryEntry {
  const factory StateHistoryEntry({
    required IssueState state,
    required DateTime changedAt,
    String? changedBy,
    String? note,
  }) = _StateHistoryEntry;

  factory StateHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$StateHistoryEntryFromJson(json);
}

/// Extended issue detail including state history.
@freezed
abstract class IssueDetail with _$IssueDetail {
  const IssueDetail._();

  const factory IssueDetail({
    required String id,
    required String type,
    required String state,
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
    @Default([]) List<StateHistoryEntry> stateHistory,
  }) = _IssueDetail;

  /// Convenience getters for backwards compatibility
  double get latitude => location.latitude;
  double get longitude => location.longitude;

  factory IssueDetail.fromJson(Map<String, dynamic> json) =>
      _$IssueDetailFromJson(json);
}
