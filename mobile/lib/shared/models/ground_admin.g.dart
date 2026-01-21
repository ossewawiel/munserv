// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ground_admin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroundAdminInfo _$GroundAdminInfoFromJson(Map<String, dynamic> json) =>
    _GroundAdminInfo(
      status: $enumDecode(_$GroundAdminStatusEnumMap, json['status']),
      since: DateTime.parse(json['since'] as String),
      responseRate: (json['responseRate'] as num).toDouble(),
      pendingVerifications: (json['pendingVerifications'] as num).toInt(),
      totalVerifications: (json['totalVerifications'] as num).toInt(),
    );

Map<String, dynamic> _$GroundAdminInfoToJson(_GroundAdminInfo instance) =>
    <String, dynamic>{
      'status': _$GroundAdminStatusEnumMap[instance.status]!,
      'since': instance.since.toIso8601String(),
      'responseRate': instance.responseRate,
      'pendingVerifications': instance.pendingVerifications,
      'totalVerifications': instance.totalVerifications,
    };

const _$GroundAdminStatusEnumMap = {
  GroundAdminStatus.active: 'active',
  GroundAdminStatus.onHold: 'on_hold',
  GroundAdminStatus.inactive: 'inactive',
};

_GroundAdminApplication _$GroundAdminApplicationFromJson(
  Map<String, dynamic> json,
) => _GroundAdminApplication(
  id: json['id'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$GroundAdminApplicationToJson(
  _GroundAdminApplication instance,
) => <String, dynamic>{'id': instance.id, 'status': instance.status};

_GroundAdminActionResponse _$GroundAdminActionResponseFromJson(
  Map<String, dynamic> json,
) => _GroundAdminActionResponse(
  status: json['status'] as String,
  member: json['member'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$GroundAdminActionResponseToJson(
  _GroundAdminActionResponse instance,
) => <String, dynamic>{'status': instance.status, 'member': instance.member};
