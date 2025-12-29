// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_issue_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReportIssueRequest _$ReportIssueRequestFromJson(Map<String, dynamic> json) =>
    _ReportIssueRequest(
      type: $enumDecode(_$IssueTypeEnumMap, json['type']),
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ReportIssueRequestToJson(_ReportIssueRequest instance) =>
    <String, dynamic>{
      'type': _$IssueTypeEnumMap[instance.type]!,
      'location': instance.location.toJson(),
      'description': instance.description,
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

_ReportIssueResponse _$ReportIssueResponseFromJson(Map<String, dynamic> json) =>
    _ReportIssueResponse(
      id: json['id'] as String,
      type: $enumDecode(_$IssueTypeEnumMap, json['type']),
      state: json['state'] as String,
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      heat: (json['heat'] as num).toInt(),
      photoUrls: (json['photoUrls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ReportIssueResponseToJson(
  _ReportIssueResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': _$IssueTypeEnumMap[instance.type]!,
  'state': instance.state,
  'location': instance.location.toJson(),
  'heat': instance.heat,
  'photoUrls': instance.photoUrls,
  'createdAt': instance.createdAt.toIso8601String(),
};
