// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Issue _$IssueFromJson(Map<String, dynamic> json) => _Issue(
  id: json['id'] as String,
  type: $enumDecode(_$IssueTypeEnumMap, json['type']),
  state: $enumDecode(_$IssueStateEnumMap, json['state']),
  location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
  address: json['address'] as String?,
  description: json['description'] as String?,
  heat: (json['heat'] as num).toInt(),
  photoUrls: (json['photoUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sectorId: json['sectorId'] as String,
  reporterId: json['reporterId'] as String,
  reportCount: (json['reportCount'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$IssueToJson(_Issue instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$IssueTypeEnumMap[instance.type]!,
  'state': _$IssueStateEnumMap[instance.state]!,
  'location': instance.location.toJson(),
  'address': instance.address,
  'description': instance.description,
  'heat': instance.heat,
  'photoUrls': instance.photoUrls,
  'sectorId': instance.sectorId,
  'reporterId': instance.reporterId,
  'reportCount': instance.reportCount,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$IssueTypeEnumMap = {
  IssueType.pothole: 'pothole',
  IssueType.waterLeak: 'water_leak',
  IssueType.sewageLeak: 'sewage_leak',
  IssueType.trafficLight: 'traffic_light',
  IssueType.streetLight: 'street_light',
  IssueType.illegalDumping: 'illegal_dumping',
  IssueType.other: 'other',
};

const _$IssueStateEnumMap = {
  IssueState.reported: 'reported',
  IssueState.confirmed: 'confirmed',
  IssueState.inProgress: 'in_progress',
  IssueState.fixed: 'fixed',
  IssueState.rejected: 'rejected',
};

_IssueSummary _$IssueSummaryFromJson(Map<String, dynamic> json) =>
    _IssueSummary(
      id: json['id'] as String,
      type: $enumDecode(_$IssueTypeEnumMap, json['type']),
      state: $enumDecode(_$IssueStateEnumMap, json['state']),
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      heat: (json['heat'] as num).toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$IssueSummaryToJson(_IssueSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$IssueTypeEnumMap[instance.type]!,
      'state': _$IssueStateEnumMap[instance.state]!,
      'location': instance.location.toJson(),
      'heat': instance.heat,
      'thumbnailUrl': instance.thumbnailUrl,
      'createdAt': instance.createdAt.toIso8601String(),
    };
