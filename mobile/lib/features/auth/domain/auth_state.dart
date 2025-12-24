import 'package:freezed_annotation/freezed_annotation.dart';

import 'login_request.dart';

part 'auth_state.freezed.dart';

/// Represents the authentication state of the app
@freezed
sealed class AuthState with _$AuthState {
  /// Initial state - checking if user is logged in
  const factory AuthState.initial() = AuthStateInitial;

  /// Loading state - during login/logout/registration
  const factory AuthState.loading() = AuthStateLoading;

  /// Authenticated state - user is logged in
  const factory AuthState.authenticated({
    required AuthTokens tokens,
    required MemberProfile profile,
    required SectorInfo sector,
  }) = AuthStateAuthenticated;

  /// Unauthenticated state - user is not logged in
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;

  /// Error state - authentication failed
  const factory AuthState.error(String message) = AuthStateError;
}

/// Extension methods for AuthState
extension AuthStateX on AuthState {
  /// Whether the user is authenticated
  bool get isAuthenticated => this is AuthStateAuthenticated;

  /// Whether we're still checking auth status
  bool get isLoading => this is AuthStateLoading || this is AuthStateInitial;

  /// Get the authenticated state if available
  AuthStateAuthenticated? get authenticatedOrNull =>
      this is AuthStateAuthenticated ? this as AuthStateAuthenticated : null;

  /// Get the current user profile if authenticated
  MemberProfile? get profileOrNull => authenticatedOrNull?.profile;

  /// Get the current access token if authenticated
  String? get accessTokenOrNull => authenticatedOrNull?.tokens.accessToken;
}
