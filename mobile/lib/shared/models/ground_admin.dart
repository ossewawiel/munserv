import 'package:freezed_annotation/freezed_annotation.dart';

part 'ground_admin.freezed.dart';
part 'ground_admin.g.dart';

/// Ground Admin status
enum GroundAdminStatus {
  active,
  @JsonValue('on_hold')
  onHold,
  inactive;

  String get displayName => switch (this) {
    active => 'Active',
    onHold => 'On Hold',
    inactive => 'Inactive',
  };

  /// Whether this status allows receiving verification requests
  bool get canReceiveRequests => this == GroundAdminStatus.active;
}

/// Ground Admin information for the current user
@freezed
abstract class GroundAdminInfo with _$GroundAdminInfo {
  const GroundAdminInfo._();

  const factory GroundAdminInfo({
    required GroundAdminStatus status,
    required DateTime since,
    required double responseRate,
    required int pendingVerifications,
    required int totalVerifications,
  }) = _GroundAdminInfo;

  /// Whether this Ground Admin is currently active
  bool get isActive => status == GroundAdminStatus.active;

  /// Formatted response rate as percentage
  String get formattedResponseRate => '${responseRate.toStringAsFixed(1)}%';

  factory GroundAdminInfo.fromJson(Map<String, dynamic> json) =>
      _$GroundAdminInfoFromJson(json);
}

/// Ground Admin application response
@freezed
abstract class GroundAdminApplication with _$GroundAdminApplication {
  const factory GroundAdminApplication({
    required String id,
    required String status,
  }) = _GroundAdminApplication;

  factory GroundAdminApplication.fromJson(Map<String, dynamic> json) =>
      _$GroundAdminApplicationFromJson(json);
}

/// Response from accepting/declining invitation
@freezed
abstract class GroundAdminActionResponse with _$GroundAdminActionResponse {
  const factory GroundAdminActionResponse({
    required String status,
    Map<String, dynamic>? member,
  }) = _GroundAdminActionResponse;

  factory GroundAdminActionResponse.fromJson(Map<String, dynamic> json) =>
      _$GroundAdminActionResponseFromJson(json);
}
