import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_phone_response.freezed.dart';
part 'check_phone_response.g.dart';

/// Response from check-phone endpoint
/// Used to determine if a phone number is registered
@freezed
abstract class CheckPhoneResponse with _$CheckPhoneResponse {
  const factory CheckPhoneResponse({
    required bool isRegistered,
  }) = _CheckPhoneResponse;

  factory CheckPhoneResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckPhoneResponseFromJson(json);
}
