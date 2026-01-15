import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';

part 'member.freezed.dart';
part 'member.g.dart';

/// Member status for registration workflow
/// MVP: always 'active'. Phase 2: 'pending' until admin approves
enum MemberStatus {
  active,
  pending,
  suspended;

  String get displayName => switch (this) {
    active => 'Active',
    pending => 'Pending Approval',
    suspended => 'Suspended',
  };
}

@freezed
abstract class Member with _$Member {
  const Member._();

  const factory Member({
    required String id,
    required String firstName,
    required String surname,
    required String phoneNumber,
    required String address,
    required GeoPoint registrationLocation,
    required String sectorId,
    required MemberStatus status,
    required DateTime createdAt,
  }) = _Member;

  /// Full name for display purposes
  String get fullName => '$firstName $surname';

  /// Short display name (first name + last initial)
  String get displayName =>
      '$firstName ${surname.isNotEmpty ? '${surname[0]}.' : ''}';

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}
