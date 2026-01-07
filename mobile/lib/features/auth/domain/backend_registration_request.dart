import 'package:freezed_annotation/freezed_annotation.dart';

part 'backend_registration_request.freezed.dart';
part 'backend_registration_request.g.dart';

/// Backend-compatible registration request (flat location)
/// Different from mock API which uses nested location object
@freezed
abstract class BackendRegistrationRequest with _$BackendRegistrationRequest {
  const factory BackendRegistrationRequest({
    required String phone,
    required String firstName,
    required String surname,
    required String pin,
    required String address,
    required String sectorId,
    required double latitude,
    required double longitude,
  }) = _BackendRegistrationRequest;

  factory BackendRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$BackendRegistrationRequestFromJson(json);
}
