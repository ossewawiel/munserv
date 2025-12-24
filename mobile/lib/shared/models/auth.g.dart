// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

_MemberProfile _$MemberProfileFromJson(Map<String, dynamic> json) =>
    _MemberProfile(
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      sector: Sector.fromJson(json['sector'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MemberProfileToJson(_MemberProfile instance) =>
    <String, dynamic>{
      'member': instance.member.toJson(),
      'sector': instance.sector.toJson(),
    };

_AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) =>
    _AuthResponse(
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      profile: MemberProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(_AuthResponse instance) =>
    <String, dynamic>{
      'tokens': instance.tokens.toJson(),
      'profile': instance.profile.toJson(),
    };
