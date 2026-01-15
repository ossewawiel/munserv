import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth_types.dart';

part 'auth_state.freezed.dart';

/// Authentication state for the app.
/// Represents all possible authentication states including intermediate states.
@freezed
sealed class AuthState with _$AuthState {
  /// Initial state - checking if user is logged in
  const factory AuthState.initial() = AuthStateInitial;

  /// Loading state - during login/logout/registration
  const factory AuthState.loading() = AuthStateLoading;

  /// Unauthenticated state - user is not logged in
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;

  /// User authenticated but must change password before proceeding
  /// This occurs on first login after admin approval (web registration flow)
  const factory AuthState.mustChangePassword({
    required AuthTokens tokens,
    required String memberId,
  }) = AuthStateMustChangePassword;

  /// Password changed, awaiting PIN setup
  /// Transition state after password change and before full authentication
  const factory AuthState.pendingPinSetup({
    required AuthTokens tokens,
    required String memberId,
  }) = AuthStatePendingPinSetup;

  /// Fully authenticated with profile loaded
  const factory AuthState.authenticated({
    required AuthTokens tokens,
    required MemberProfile profile,
    required SectorInfo sector,
  }) = AuthStateAuthenticated;

  /// Authentication error occurred
  const factory AuthState.error(String message) = AuthStateError;
}

/// Extension methods for convenient state checking
extension AuthStateX on AuthState {
  /// Whether the user is fully authenticated
  bool get isAuthenticated => this is AuthStateAuthenticated;

  /// Whether we're still checking auth status
  bool get isLoading => this is AuthStateLoading || this is AuthStateInitial;

  /// Whether user needs to change their password
  bool get needsPasswordChange => this is AuthStateMustChangePassword;

  /// Whether user needs to set up their PIN
  bool get needsPinSetup => this is AuthStatePendingPinSetup;

  /// Get tokens from any state that has them
  AuthTokens? get tokens => switch (this) {
    AuthStateAuthenticated(:final tokens) => tokens,
    AuthStateMustChangePassword(:final tokens) => tokens,
    AuthStatePendingPinSetup(:final tokens) => tokens,
    _ => null,
  };

  /// Get member ID from any state that has it
  String? get memberId => switch (this) {
    AuthStateAuthenticated(:final profile) => profile.id,
    AuthStateMustChangePassword(:final memberId) => memberId,
    AuthStatePendingPinSetup(:final memberId) => memberId,
    _ => null,
  };

  /// Get the authenticated state if available
  AuthStateAuthenticated? get authenticatedOrNull =>
      this is AuthStateAuthenticated ? this as AuthStateAuthenticated : null;

  /// Get the current user profile if authenticated
  MemberProfile? get profileOrNull => authenticatedOrNull?.profile;

  /// Get the current access token if authenticated
  String? get accessTokenOrNull => authenticatedOrNull?.tokens.accessToken;

  /// Get the current sector ID if authenticated
  String? get sectorIdOrNull => authenticatedOrNull?.sector.id;

  /// Get the current sector info if authenticated
  SectorInfo? get sectorOrNull => authenticatedOrNull?.sector;
}
