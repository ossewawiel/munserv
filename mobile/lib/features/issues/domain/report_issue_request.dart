import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/geo_point.dart';
import '../../../shared/models/issue_type.dart';

part 'report_issue_request.freezed.dart';
part 'report_issue_request.g.dart';

/// Request model for reporting a new issue.
/// Note: Photos are handled separately in multipart upload.
@freezed
abstract class ReportIssueRequest with _$ReportIssueRequest {
  const factory ReportIssueRequest({
    required IssueType type,
    required GeoPoint location,
    String? description,
  }) = _ReportIssueRequest;

  factory ReportIssueRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportIssueRequestFromJson(json);
}

/// Response after successfully reporting an issue.
@freezed
abstract class ReportIssueResponse with _$ReportIssueResponse {
  const factory ReportIssueResponse({
    required String id,
    required IssueType type,
    required String state,
    required GeoPoint location,
    required int heat,
    required List<String> photoUrls,
    required DateTime createdAt,
  }) = _ReportIssueResponse;

  factory ReportIssueResponse.fromJson(Map<String, dynamic> json) =>
      _$ReportIssueResponseFromJson(json);
}
