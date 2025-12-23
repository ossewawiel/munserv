// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  phoneNumber: json['phoneNumber'] as String,
  displayName: json['displayName'] as String,
  sectorId: json['sectorId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'phoneNumber': instance.phoneNumber,
  'displayName': instance.displayName,
  'sectorId': instance.sectorId,
  'createdAt': instance.createdAt.toIso8601String(),
};
