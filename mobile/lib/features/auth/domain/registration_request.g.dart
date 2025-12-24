// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegistrationRequest _$RegistrationRequestFromJson(Map<String, dynamic> json) =>
    _RegistrationRequest(
      firstName: json['firstName'] as String,
      surname: json['surname'] as String,
      pin: json['pin'] as String,
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      address: json['address'] as String,
    );

Map<String, dynamic> _$RegistrationRequestToJson(
  _RegistrationRequest instance,
) => <String, dynamic>{
  'firstName': instance.firstName,
  'surname': instance.surname,
  'pin': instance.pin,
  'location': instance.location.toJson(),
  'address': instance.address,
};
