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
  const factory OtpVerifyResult.newUser({
    required String tempToken,
  }) = OtpVerifyResultNewUser;

  /// Existing user - returns full auth response (already logged in)
  const factory OtpVerifyResult.existingUser({
    required AuthTokens tokens,
    required AuthProfile profile,
  }) = OtpVerifyResultExistingUser;

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) =>
      _$OtpVerifyResultFromJson(json);

  /// Whether this is a new user needing registration
  bool get isNewUser => this is OtpVerifyResultNewUser;

  /// Whether this is an existing user
  bool get isExistingUser => this is OtpVerifyResultExistingUser;
}
