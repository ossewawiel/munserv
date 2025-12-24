import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_request.freezed.dart';
part 'otp_request.g.dart';

/// Request to send OTP to a phone number
@freezed
abstract class OtpRequest with _$OtpRequest {
  const factory OtpRequest({
    required String phoneNumber,
  }) = _OtpRequest;

  factory OtpRequest.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestFromJson(json);
}

/// Response from OTP request
@freezed
abstract class OtpRequestResponse with _$OtpRequestResponse {
  const factory OtpRequestResponse({
    required String message,
    required int expiresInSeconds,
  }) = _OtpRequestResponse;

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestResponseFromJson(json);
}
