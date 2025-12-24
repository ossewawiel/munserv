import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:munserv_mobile/shared/models/geo_point.dart';

part 'registration_request.freezed.dart';
part 'registration_request.g.dart';

/// Request to complete registration after OTP verification
@freezed
abstract class RegistrationRequest with _$RegistrationRequest {
  const factory RegistrationRequest({
    required String firstName,
    required String surname,
    required String pin,
    required GeoPoint location,
    required String address,
  }) = _RegistrationRequest;

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$RegistrationRequestFromJson(json);
}
