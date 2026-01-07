// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberProfileResponse _$MemberProfileResponseFromJson(
  Map<String, dynamic> json,
) => _MemberProfileResponse(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  surname: json['surname'] as String,
  phoneNumber: json['phoneNumber'] as String,
  address: json['address'] as String,
  registrationLocation: GeoPoint.fromJson(
    json['registrationLocation'] as Map<String, dynamic>,
  ),
  sectorId: json['sectorId'] as String,
  status: json['status'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$MemberProfileResponseToJson(
  _MemberProfileResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'surname': instance.surname,
  'phoneNumber': instance.phoneNumber,
  'address': instance.address,
  'registrationLocation': instance.registrationLocation.toJson(),
  'sectorId': instance.sectorId,
  'status': instance.status,
  'createdAt': instance.createdAt,
};
