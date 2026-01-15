// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StateHistoryEntry _$StateHistoryEntryFromJson(Map<String, dynamic> json) =>
    _StateHistoryEntry(
      state: $enumDecode(_$IssueStateEnumMap, json['state']),
      changedAt: DateTime.parse(json['changedAt'] as String),
      changedBy: json['changedBy'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$StateHistoryEntryToJson(_StateHistoryEntry instance) =>
    <String, dynamic>{
      'state': _$IssueStateEnumMap[instance.state]!,
      'changedAt': instance.changedAt.toIso8601String(),
      'changedBy': instance.changedBy,
      'note': instance.note,
    };

const _$IssueStateEnumMap = {
  IssueState.reported: 'reported',
  IssueState.confirmed: 'confirmed',
  IssueState.inProgress: 'in_progress',
  IssueState.fixed: 'fixed',
  IssueState.rejected: 'rejected',
};

_IssueDetail _$IssueDetailFromJson(Map<String, dynamic> json) => _IssueDetail(
  id: json['id'] as String,
  type: json['type'] as String,
  state: json['state'] as String,
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
  stateHistory:
      (json['stateHistory'] as List<dynamic>?)
          ?.map((e) => StateHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$IssueDetailToJson(_IssueDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'state': instance.state,
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
      'stateHistory': instance.stateHistory.map((e) => e.toJson()).toList(),
    };
