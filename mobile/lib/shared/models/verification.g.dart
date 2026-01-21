// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingVerification _$PendingVerificationFromJson(Map<String, dynamic> json) =>
    _PendingVerification(
      verificationId: json['verificationId'] as String,
      issueId: json['issueId'] as String,
      issueType: json['issueType'] as String,
      verificationType: json['verificationType'] as String,
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      distance: (json['distance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PendingVerificationToJson(
  _PendingVerification instance,
) => <String, dynamic>{
  'verificationId': instance.verificationId,
  'issueId': instance.issueId,
  'issueType': instance.issueType,
  'verificationType': instance.verificationType,
  'location': instance.location.toJson(),
  'requestedAt': instance.requestedAt.toIso8601String(),
  'distance': instance.distance,
};

_VerificationSubmitRequest _$VerificationSubmitRequestFromJson(
  Map<String, dynamic> json,
) => _VerificationSubmitRequest(
  verificationId: json['verificationId'] as String,
  result: json['result'] as String,
  reason: json['reason'] as String?,
  note: json['note'] as String?,
  photoId: json['photoId'] as String?,
);

Map<String, dynamic> _$VerificationSubmitRequestToJson(
  _VerificationSubmitRequest instance,
) => <String, dynamic>{
  'verificationId': instance.verificationId,
  'result': instance.result,
  'reason': instance.reason,
  'note': instance.note,
  'photoId': instance.photoId,
};

_IssueVerification _$IssueVerificationFromJson(Map<String, dynamic> json) =>
    _IssueVerification(
      id: json['id'] as String,
      issueId: json['issueId'] as String,
      verificationType: json['verificationType'] as String,
      assignedTo: json['assignedTo'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      result: json['result'] as String?,
      reason: json['reason'] as String?,
      note: json['note'] as String?,
      photoId: json['photoId'] as String?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      status: json['status'] as String,
    );

Map<String, dynamic> _$IssueVerificationToJson(_IssueVerification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'issueId': instance.issueId,
      'verificationType': instance.verificationType,
      'assignedTo': instance.assignedTo,
      'verifiedBy': instance.verifiedBy,
      'result': instance.result,
      'reason': instance.reason,
      'note': instance.note,
      'photoId': instance.photoId,
      'requestedAt': instance.requestedAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'status': instance.status,
    };

_PendingVerificationsResponse _$PendingVerificationsResponseFromJson(
  Map<String, dynamic> json,
) => _PendingVerificationsResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => PendingVerification.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PendingVerificationsResponseToJson(
  _PendingVerificationsResponse instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
