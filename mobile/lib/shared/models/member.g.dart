// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  surname: json['surname'] as String,
  phoneNumber: json['phoneNumber'] as String,
  address: json['address'] as String,
  registrationLocation: GeoPoint.fromJson(
    json['registrationLocation'] as Map<String, dynamic>,
  ),
  sectorId: json['sectorId'] as String,
  status: $enumDecode(_$MemberStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'surname': instance.surname,
  'phoneNumber': instance.phoneNumber,
  'address': instance.address,
  'registrationLocation': instance.registrationLocation.toJson(),
  'sectorId': instance.sectorId,
  'status': _$MemberStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$MemberStatusEnumMap = {
  MemberStatus.active: 'active',
  MemberStatus.pending: 'pending',
  MemberStatus.suspended: 'suspended',
};
