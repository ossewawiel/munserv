import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth_types.dart';

part 'backend_login_response.freezed.dart';
part 'backend_login_response.g.dart';

/// Backend login/registration response (flat structure)
/// Different from mock API which returns nested { tokens, profile }
@freezed
abstract class BackendLoginResponse with _$BackendLoginResponse {
  const BackendLoginResponse._();

  const factory BackendLoginResponse({
    required String memberId,
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    @Default('Bearer') String tokenType,
  }) = _BackendLoginResponse;

  factory BackendLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$BackendLoginResponseFromJson(json);

  /// Convert to existing AuthTokens format for compatibility
  AuthTokens toAuthTokens() => AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: DateTime.now()
        .add(Duration(seconds: expiresIn))
        .toUtc()
        .toIso8601String(),
  );
}
