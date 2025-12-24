// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      phoneNumber: json['phoneNumber'] as String,
      pin: json['pin'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{'phoneNumber': instance.phoneNumber, 'pin': instance.pin};

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresAt: json['expiresAt'] as String?,
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt,
    };

_MemberProfile _$MemberProfileFromJson(Map<String, dynamic> json) =>
    _MemberProfile(
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

Map<String, dynamic> _$MemberProfileToJson(_MemberProfile instance) =>
    <String, dynamic>{
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

_SectorInfo _$SectorInfoFromJson(Map<String, dynamic> json) => _SectorInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  center: GeoPoint.fromJson(json['center'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SectorInfoToJson(_SectorInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'center': instance.center.toJson(),
    };

_AuthProfile _$AuthProfileFromJson(Map<String, dynamic> json) => _AuthProfile(
  member: MemberProfile.fromJson(json['member'] as Map<String, dynamic>),
  sector: SectorInfo.fromJson(json['sector'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthProfileToJson(_AuthProfile instance) =>
    <String, dynamic>{
      'member': instance.member.toJson(),
      'sector': instance.sector.toJson(),
    };

_AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) =>
    _AuthResponse(
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      profile: AuthProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(_AuthResponse instance) =>
    <String, dynamic>{
      'tokens': instance.tokens.toJson(),
      'profile': instance.profile.toJson(),
    };
