import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

/// Reasons why a Ground Admin cannot verify an issue
enum VerificationReason {
  busy,
  away,
  @JsonValue('cannot_find')
  cannotFind,
  @JsonValue('wrong_location')
  wrongLocation,
  @JsonValue('not_an_issue')
  notAnIssue;

  String get displayName => switch (this) {
        busy => 'I am busy right now',
        away => 'I am away from the area',
        cannotFind => 'Cannot find the issue',
        wrongLocation => 'Location seems incorrect',
        notAnIssue => 'This is not actually an issue',
      };
}

/// Verification result types
enum VerificationResult {
  confirmed,
  @JsonValue('not_found')
  notFound,
  @JsonValue('not_fixed')
  notFixed,
  @JsonValue('cannot_verify')
  cannotVerify;

  String get displayName => switch (this) {
        confirmed => 'Confirmed',
        notFound => 'Not Found',
        notFixed => 'Not Fixed',
        cannotVerify => 'Cannot Verify',
      };
}

/// Verification type
enum VerificationType {
  existence,
  fix;

  String get displayName => switch (this) {
        existence => 'Existence Verification',
        fix => 'Fix Verification',
      };
}

/// A pending verification request for a Ground Admin
@freezed
abstract class PendingVerification with _$PendingVerification {
  const PendingVerification._();

  const factory PendingVerification({
    required String verificationId,
    required String issueId,
    required String issueType,
    required String verificationType,
    required GeoPoint location,
    required DateTime requestedAt,
    double? distance,
  }) = _PendingVerification;

  /// Whether this is an existence verification
  bool get isExistenceVerification => verificationType == 'existence';

  /// Whether this is a fix verification
  bool get isFixVerification => verificationType == 'fix';

  /// Formatted distance if available
  String? get formattedDistance {
    if (distance == null) return null;
    if (distance! < 1000) {
      return '${distance!.toInt()}m away';
    }
    return '${(distance! / 1000).toStringAsFixed(1)}km away';
  }

  factory PendingVerification.fromJson(Map<String, dynamic> json) =>
      _$PendingVerificationFromJson(json);
}

/// Response for submitting a verification
@freezed
abstract class VerificationSubmitRequest with _$VerificationSubmitRequest {
  const factory VerificationSubmitRequest({
    required String verificationId,
    required String result,
    String? reason,
    String? note,
    String? photoId,
  }) = _VerificationSubmitRequest;

  factory VerificationSubmitRequest.fromJson(Map<String, dynamic> json) =>
      _$VerificationSubmitRequestFromJson(json);
}

/// Issue verification record
@freezed
abstract class IssueVerification with _$IssueVerification {
  const factory IssueVerification({
    required String id,
    required String issueId,
    required String verificationType,
    String? assignedTo,
    String? verifiedBy,
    String? result,
    String? reason,
    String? note,
    String? photoId,
    required DateTime requestedAt,
    DateTime? respondedAt,
    required String status,
  }) = _IssueVerification;

  factory IssueVerification.fromJson(Map<String, dynamic> json) =>
      _$IssueVerificationFromJson(json);
}

/// List of pending verifications response
@freezed
abstract class PendingVerificationsResponse with _$PendingVerificationsResponse {
  const factory PendingVerificationsResponse({
    required List<PendingVerification> items,
  }) = _PendingVerificationsResponse;

  factory PendingVerificationsResponse.fromJson(Map<String, dynamic> json) =>
      _$PendingVerificationsResponseFromJson(json);
}
