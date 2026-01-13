// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberLoginResponse _$MemberLoginResponseFromJson(Map<String, dynamic> json) =>
    _MemberLoginResponse(
      memberId: json['memberId'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      mustChangePassword: json['mustChangePassword'] as bool,
    );

Map<String, dynamic> _$MemberLoginResponseToJson(
  _MemberLoginResponse instance,
) => <String, dynamic>{
  'memberId': instance.memberId,
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'expiresIn': instance.expiresIn,
  'mustChangePassword': instance.mustChangePassword,
};
