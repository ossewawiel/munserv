# Investigation: Mobile fingerprint login issue

**Issue:** #15
**Date:** 2026-01-21
**Platforms:** Mobile (Flutter)

## Problem Statement

When the mobile app starts and jumps to the PIN login screen, the PIN login gives the error `LocalAuthException(code authInProgress, null, null)`. The fingerprint dialog then opens but when supplying the fingerprint nothing happens. User needs to click on the "use fingerprint" button again to log in.

## Investigation Steps

1. **Reviewed `PinLoginPage`** (`mobile/lib/features/auth/presentation/pages/pin_login_page.dart`)
   - `initState()` schedules `_attemptBiometricLogin()` via `WidgetsBinding.instance.addPostFrameCallback()`
   - This means biometric authentication is triggered automatically after the first frame

2. **Reviewed `BiometricService`** (`mobile/lib/shared/services/biometric_service.dart`)
   - Uses `local_auth` package version 3.0.0
   - `authenticate()` method does not handle concurrent authentication attempts
   - No mechanism to stop previous authentication before starting a new one

3. **Reviewed `auth_providers.dart`** (`mobile/lib/features/auth/providers/auth_providers.dart`)
   - `authenticateAndGetPin()` in `BiometricLoginNotifier` does not guard against concurrent calls
   - No `stopAuthentication()` call before starting authentication

4. **Root cause identified**: The `local_auth` package throws `LocalAuthException(code: authInProgress)` when `authenticate()` is called while another authentication is already in progress. This happens because:
   - The automatic biometric prompt from `initState()` starts an authentication
   - The PinInputField's `autoFocus: true` may trigger the keyboard, which can cause a widget rebuild
   - Any rebuild can trigger another authentication attempt through various providers
   - There's no guard against concurrent authentication attempts

## Root Cause

**Race Condition in Biometric Authentication Initialization**

The `PinLoginPage` triggers biometric authentication automatically in `initState()` via `addPostFrameCallback()`. However:

1. There's no singleton/mutex pattern to prevent concurrent authentication attempts
2. The `_biometricAttempted` flag in `PinLoginPage` only prevents the page's `_attemptBiometricLogin()` from being called twice, but doesn't prevent concurrent authentication at the service level
3. The `BiometricService.authenticate()` method doesn't call `stopAuthentication()` before starting a new authentication
4. When the fingerprint dialog is showing, any interaction that causes a widget rebuild could trigger another auth attempt through Riverpod providers

## Affected Components

### Mobile
- `mobile/lib/shared/services/biometric_service.dart` - Missing concurrent auth protection
- `mobile/lib/features/auth/providers/auth_providers.dart` - `BiometricLoginNotifier.authenticateAndGetPin()` needs guard
- `mobile/lib/features/auth/presentation/pages/pin_login_page.dart` - Auto-trigger logic may need refinement

## Fix Approach

1. **Add authentication state tracking in `BiometricService`**
   - Add a private `bool _isAuthenticating` flag
   - Call `stopAuthentication()` if auth is already in progress before starting new auth
   - Set flag to `true` before auth, `false` in finally block

2. **Handle `LocalAuthException` properly**
   - Catch `LocalAuthException` specifically
   - Check for `LocalAuthExceptionCode.authInProgress` and handle gracefully
   - Return appropriate `BiometricResult` for each error code

3. **Add mutex/lock pattern for authentication**
   - Consider using a `Completer` or lock to ensure only one authentication can run at a time
   - Return the existing result if auth is already in progress

## References

- [local_auth package](https://pub.dev/packages/local_auth)
- [Flutter issue #133318 - Using LocalAuthentication.authenticate repeatedly with short intervals](https://github.com/flutter/flutter/issues/133318)
- [Flutter issue #45536 - local_auth called two times](https://github.com/flutter/flutter/issues/45536)
