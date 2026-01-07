// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackendLoginResponse _$BackendLoginResponseFromJson(
  Map<String, dynamic> json,
) => _BackendLoginResponse(
  memberId: json['memberId'] as String,
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: (json['expiresIn'] as num).toInt(),
  tokenType: json['tokenType'] as String? ?? 'Bearer',
);

Map<String, dynamic> _$BackendLoginResponseToJson(
  _BackendLoginResponse instance,
) => <String, dynamic>{
  'memberId': instance.memberId,
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'expiresIn': instance.expiresIn,
  'tokenType': instance.tokenType,
};
