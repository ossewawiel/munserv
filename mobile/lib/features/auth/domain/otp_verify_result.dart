import 'package:freezed_annotation/freezed_annotation.dart';

import 'login_request.dart';

part 'otp_verify_result.freezed.dart';
part 'otp_verify_result.g.dart';

/// Request to verify OTP
@freezed
abstract class OtpVerifyRequest with _$OtpVerifyRequest {
  const factory OtpVerifyRequest({
    required String phoneNumber,
    required String otp,
  }) = _OtpVerifyRequest;

  factory OtpVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$OtpVerifyRequestFromJson(json);
}

/// Result of OTP verification - either a new user or existing user
@Freezed(unionKey: 'status', unionValueCase: FreezedUnionCase.snake)
sealed class OtpVerifyResult with _$OtpVerifyResult {
  const OtpVerifyResult._();

  /// New user - needs to complete registration
  /// tempToken is optional (mock API uses it, backend doesn't)
  const factory OtpVerifyResult.newUser({
    @Default('') String tempToken,
  }) = OtpVerifyResultNewUser;

  /// Existing user - needs to login with PIN
  /// tokens/profile are optional for backend flow (login happens separately)
  /// For mock API: returns tokens/profile immediately
  /// For backend: returns null tokens/profile, user must login with PIN
  const factory OtpVerifyResult.existingUser({
    AuthTokens? tokens,
    AuthProfile? profile,
  }) = OtpVerifyResultExistingUser;

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) =>
      _$OtpVerifyResultFromJson(json);

  /// Whether this is a new user needing registration
  bool get isNewUser => this is OtpVerifyResultNewUser;

  /// Whether this is an existing user (needs to login with PIN)
  bool get isExistingUser => this is OtpVerifyResultExistingUser;

  /// Whether existing user has tokens (mock API flow)
  bool get hasTokens =>
      this is OtpVerifyResultExistingUser &&
      (this as OtpVerifyResultExistingUser).tokens != null;
}
