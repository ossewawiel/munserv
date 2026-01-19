// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueFilter _$IssueFilterFromJson(Map<String, dynamic> json) => _IssueFilter(
  sectorId: json['sectorId'] as String,
  state: $enumDecodeNullable(_$IssueStateEnumMap, json['state']),
  type: $enumDecodeNullable(_$IssueTypeEnumMap, json['type']),
  page: (json['page'] as num?)?.toInt() ?? 1,
  limit: (json['limit'] as num?)?.toInt() ?? 20,
  sortBy:
      $enumDecodeNullable(_$IssueSortByEnumMap, json['sortBy']) ??
      IssueSortBy.heat,
);

Map<String, dynamic> _$IssueFilterToJson(_IssueFilter instance) =>
    <String, dynamic>{
      'sectorId': instance.sectorId,
      'state': _$IssueStateEnumMap[instance.state],
      'type': _$IssueTypeEnumMap[instance.type],
      'page': instance.page,
      'limit': instance.limit,
      'sortBy': _$IssueSortByEnumMap[instance.sortBy]!,
    };

const _$IssueStateEnumMap = {
  IssueState.reported: 'reported',
  IssueState.confirmed: 'confirmed',
  IssueState.inProgress: 'in_progress',
  IssueState.fixed: 'fixed',
  IssueState.rejected: 'rejected',
};

const _$IssueTypeEnumMap = {
  IssueType.pothole: 'pothole',
  IssueType.waterLeak: 'water_leak',
  IssueType.sewageLeak: 'sewage_leak',
  IssueType.trafficLight: 'traffic_light',
  IssueType.streetLight: 'street_light',
  IssueType.illegalDumping: 'illegal_dumping',
  IssueType.roadDamage: 'road_damage',
  IssueType.other: 'other',
};

const _$IssueSortByEnumMap = {
  IssueSortBy.heat: 'heat',
  IssueSortBy.createdAt: 'created_at',
};
