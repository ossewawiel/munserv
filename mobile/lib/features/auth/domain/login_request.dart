import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

part 'login_request.freezed.dart';
part 'login_request.g.dart';

/// Request to login with phone and PIN
@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String phoneNumber,
    required String pin,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

/// Auth tokens returned from login/registration
@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

/// Member profile data
@freezed
abstract class MemberProfile with _$MemberProfile {
  const MemberProfile._();

  const factory MemberProfile({
    required String id,
    required String firstName,
    required String surname,
    required String phoneNumber,
    required String address,
    required GeoPoint registrationLocation,
    required String sectorId,
    required String status,
    required String createdAt,
  }) = _MemberProfile;

  factory MemberProfile.fromJson(Map<String, dynamic> json) =>
      _$MemberProfileFromJson(json);

  /// Full name combining first name and surname
  String get fullName => '$firstName $surname';
}

/// Sector info returned with auth response
@freezed
abstract class SectorInfo with _$SectorInfo {
  const factory SectorInfo({
    required String id,
    required String name,
    required GeoPoint center,
  }) = _SectorInfo;

  factory SectorInfo.fromJson(Map<String, dynamic> json) =>
      _$SectorInfoFromJson(json);
}

/// Profile containing member and sector info
@freezed
abstract class AuthProfile with _$AuthProfile {
  const factory AuthProfile({
    required MemberProfile member,
    required SectorInfo sector,
  }) = _AuthProfile;

  factory AuthProfile.fromJson(Map<String, dynamic> json) =>
      _$AuthProfileFromJson(json);
}

/// Response from login or registration completion
@freezed
abstract class AuthResponse with _$AuthResponse {
  const AuthResponse._();

  const factory AuthResponse({
    required AuthTokens tokens,
    required AuthProfile profile,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  /// Convenience accessors
  MemberProfile get member => profile.member;
  SectorInfo get sector => profile.sector;
}

/// For backwards compatibility / simpler access
typedef UserProfile = MemberProfile;
