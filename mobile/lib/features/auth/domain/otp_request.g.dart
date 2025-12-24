// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtpRequest _$OtpRequestFromJson(Map<String, dynamic> json) =>
    _OtpRequest(phoneNumber: json['phoneNumber'] as String);

Map<String, dynamic> _$OtpRequestToJson(_OtpRequest instance) =>
    <String, dynamic>{'phoneNumber': instance.phoneNumber};

_OtpRequestResponse _$OtpRequestResponseFromJson(Map<String, dynamic> json) =>
    _OtpRequestResponse(
      message: json['message'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$OtpRequestResponseToJson(_OtpRequestResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'expiresInSeconds': instance.expiresInSeconds,
    };
