import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_login_response.freezed.dart';
part 'member_login_response.g.dart';

/// Response from POST /auth/member/login
/// Used for email+password authentication in the web registration flow
@freezed
abstract class MemberLoginResponse with _$MemberLoginResponse {
  const factory MemberLoginResponse({
    required String memberId,
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required bool mustChangePassword,
  }) = _MemberLoginResponse;

  factory MemberLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$MemberLoginResponseFromJson(json);
}
