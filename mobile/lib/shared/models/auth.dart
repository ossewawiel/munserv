import 'package:freezed_annotation/freezed_annotation.dart';

import 'member.dart';
import 'sector.dart';

part 'auth.freezed.dart';
part 'auth.g.dart';

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

@freezed
abstract class MemberProfile with _$MemberProfile {
  const factory MemberProfile({
    required Member member,
    required Sector sector,
  }) = _MemberProfile;

  factory MemberProfile.fromJson(Map<String, dynamic> json) =>
      _$MemberProfileFromJson(json);
}

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required AuthTokens tokens,
    required MemberProfile profile,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
