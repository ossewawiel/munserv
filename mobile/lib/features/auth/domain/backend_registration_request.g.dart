// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_registration_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackendRegistrationRequest _$BackendRegistrationRequestFromJson(
  Map<String, dynamic> json,
) => _BackendRegistrationRequest(
  phone: json['phone'] as String,
  firstName: json['firstName'] as String,
  surname: json['surname'] as String,
  pin: json['pin'] as String,
  address: json['address'] as String,
  sectorId: json['sectorId'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$BackendRegistrationRequestToJson(
  _BackendRegistrationRequest instance,
) => <String, dynamic>{
  'phone': instance.phone,
  'firstName': instance.firstName,
  'surname': instance.surname,
  'pin': instance.pin,
  'address': instance.address,
  'sectorId': instance.sectorId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
