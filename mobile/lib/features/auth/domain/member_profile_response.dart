import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/geo_point.dart';
import 'auth_types.dart';

part 'member_profile_response.freezed.dart';
part 'member_profile_response.g.dart';

/// Response from /api/v1/members/me endpoint
/// Returns current authenticated member's profile
@freezed
abstract class MemberProfileResponse with _$MemberProfileResponse {
  const MemberProfileResponse._();

  const factory MemberProfileResponse({
    required String id,
    required String firstName,
    required String surname,
    required String phoneNumber,
    required String address,
    required GeoPoint registrationLocation,
    required String sectorId,
    required String status,
    required String createdAt,
  }) = _MemberProfileResponse;

  factory MemberProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$MemberProfileResponseFromJson(json);

  /// Convert to existing MemberProfile format for compatibility
  MemberProfile toMemberProfile() => MemberProfile(
        id: id,
        firstName: firstName,
        surname: surname,
        phoneNumber: phoneNumber,
        address: address,
        registrationLocation: registrationLocation,
        sectorId: sectorId,
        status: status,
        createdAt: createdAt,
      );
}
