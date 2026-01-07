// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_verify_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtpVerifyRequest _$OtpVerifyRequestFromJson(Map<String, dynamic> json) =>
    _OtpVerifyRequest(
      phoneNumber: json['phoneNumber'] as String,
      otp: json['otp'] as String,
    );

Map<String, dynamic> _$OtpVerifyRequestToJson(_OtpVerifyRequest instance) =>
    <String, dynamic>{'phoneNumber': instance.phoneNumber, 'otp': instance.otp};

OtpVerifyResultNewUser _$OtpVerifyResultNewUserFromJson(
  Map<String, dynamic> json,
) => OtpVerifyResultNewUser(
  tempToken: json['tempToken'] as String? ?? '',
  $type: json['status'] as String?,
);

Map<String, dynamic> _$OtpVerifyResultNewUserToJson(
  OtpVerifyResultNewUser instance,
) => <String, dynamic>{
  'tempToken': instance.tempToken,
  'status': instance.$type,
};

OtpVerifyResultExistingUser _$OtpVerifyResultExistingUserFromJson(
  Map<String, dynamic> json,
) => OtpVerifyResultExistingUser(
  tokens: json['tokens'] == null
      ? null
      : AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
  profile: json['profile'] == null
      ? null
      : AuthProfile.fromJson(json['profile'] as Map<String, dynamic>),
  $type: json['status'] as String?,
);

Map<String, dynamic> _$OtpVerifyResultExistingUserToJson(
  OtpVerifyResultExistingUser instance,
) => <String, dynamic>{
  'tokens': instance.tokens?.toJson(),
  'profile': instance.profile?.toJson(),
  'status': instance.$type,
};
