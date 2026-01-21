---
issue: 15
title: "Mobile fingerprint login issue"
platform: mobile
status: completed
created_by: central-agent
created_at: 2026-01-21
updated_at: 2026-01-21
started_at: 2026-01-21
completed_at: 2026-01-21
dependencies: []
files_changed:
  - lib/shared/services/biometric_service.dart
tests_added:
  - test/shared/services/biometric_service_test.dart (6 new tests)
commits: []
blockers: []
---

# Issue #15: Mobile fingerprint login issue (Mobile)

## Context

When the mobile app starts and navigates to the PIN login screen, biometric authentication is automatically triggered. However, a race condition causes `LocalAuthException(code authInProgress)` to be thrown, resulting in the fingerprint dialog appearing but not responding to the first fingerprint input. Users must tap "Use fingerprint" again to successfully log in.

## Root Cause

The `BiometricService.authenticate()` method does not handle concurrent authentication attempts. The `local_auth` package throws `LocalAuthException` with code `authInProgress` when `authenticate()` is called while another authentication is already in progress.

The issue occurs because:
1. `PinLoginPage.initState()` triggers biometric auth via `addPostFrameCallback()`
2. No mutex/guard prevents concurrent authentication at the service level
3. Widget rebuilds or provider re-evaluations can trigger additional auth attempts
4. The existing `_biometricAttempted` flag only guards at the page level, not service level

## What To Fix

### Files To Modify

1. `lib/shared/services/biometric_service.dart`
2. `lib/features/auth/providers/auth_providers.dart` (minor adjustment)

### Changes Required

#### 1. Update `BiometricService` to prevent concurrent authentication

Add authentication state tracking and call `stopAuthentication()` before starting new auth:

```dart
class BiometricService {
  final LocalAuthentication _auth;
  bool _isAuthenticating = false;
  Completer<BiometricResult>? _authCompleter;

  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  // ... existing methods ...

  /// Authenticate using biometrics
  /// Returns the result of the authentication attempt
  /// If authentication is already in progress, waits for it to complete
  Future<BiometricResult> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
  }) async {
    // If auth is already in progress, return the existing future
    if (_isAuthenticating && _authCompleter != null) {
      return _authCompleter!.future;
    }

    _isAuthenticating = true;
    _authCompleter = Completer<BiometricResult>();

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        final result = BiometricResult.notAvailable();
        _authCompleter!.complete(result);
        return result;
      }

      // Stop any lingering authentication before starting new one
      await _auth.stopAuthentication();

      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );

      final result = didAuthenticate
          ? BiometricResult.success()
          : BiometricResult.failed();
      _authCompleter!.complete(result);
      return result;
    } on LocalAuthException catch (e) {
      // Handle specific LocalAuth exceptions
      final result = switch (e.code) {
        LocalAuthExceptionCode.authInProgress => BiometricResult.error('Authentication already in progress'),
        LocalAuthExceptionCode.biometricEnrollmentRequired => BiometricResult.notAvailable(),
        LocalAuthExceptionCode.biometricNotAvailable => BiometricResult.notAvailable(),
        LocalAuthExceptionCode.notEnrolled => BiometricResult.notAvailable(),
        LocalAuthExceptionCode.passcodeNotSet => BiometricResult.notAvailable(),
        LocalAuthExceptionCode.userCanceled => BiometricResult.failed(),
        _ => BiometricResult.error(e.message ?? 'Authentication failed'),
      };
      _authCompleter!.complete(result);
      return result;
    } catch (e) {
      final result = BiometricResult.error(e.toString());
      _authCompleter!.complete(result);
      return result;
    } finally {
      _isAuthenticating = false;
      _authCompleter = null;
    }
  }

  /// Stop any ongoing authentication
  Future<void> stopAuthentication() async {
    if (_isAuthenticating) {
      await _auth.stopAuthentication();
    }
  }
}
```

#### 2. Update imports in `biometric_service.dart`

Add the `LocalAuthException` import:

```dart
import 'package:local_auth/error_codes.dart' as local_auth_error;
```

Note: Check the actual import path for `LocalAuthException` and `LocalAuthExceptionCode` in `local_auth` 3.0.0.

## Acceptance Criteria

- [ ] App starts and fingerprint dialog appears
- [ ] First fingerprint input is recognized and processed
- [ ] No `LocalAuthException(code authInProgress)` error in logs
- [ ] User can successfully log in with fingerprint on first attempt
- [ ] Tapping "Use fingerprint" button still works for retry
- [ ] Manual PIN entry still works as fallback
- [ ] Tests pass
- [ ] Quality checks pass (`flutter analyze`)

## Dependencies

- None

## Testing Notes

To reproduce the original bug:
1. Start the app fresh (close and reopen)
2. Ensure biometric login is enabled
3. Watch for the error in debug console
4. Notice fingerprint dialog doesn't respond to first input

To verify the fix:
1. Same steps as above
2. First fingerprint input should successfully log in
3. No error in console

## Implementation Notes

### Changes Made

1. **Added concurrent authentication guard** (`lib/shared/services/biometric_service.dart:57-114`)
   - Added `_isAuthenticating` flag and `_authCompleter` to track auth state
   - If auth is already in progress, returns the existing future instead of starting new auth
   - This prevents race conditions when `authenticate()` is called multiple times

2. **Added `stopAuthentication()` call before new auth** (`lib/shared/services/biometric_service.dart:78`)
   - Calls `_auth.stopAuthentication()` before starting new authentication
   - Clears any lingering authentication state from previous attempts

3. **Added proper `LocalAuthException` handling** (`lib/shared/services/biometric_service.dart:90-106`)
   - Handles specific exception codes with appropriate `BiometricResult` types:
     - `authInProgress` → `BiometricResult.error()`
     - `noBiometricsEnrolled`, `noBiometricHardware`, `noCredentialsSet`, `biometricHardwareTemporarilyUnavailable` → `BiometricResult.notAvailable()`
     - `userCanceled`, `userRequestedFallback` → `BiometricResult.failed()`
     - Others → `BiometricResult.error()` with description

4. **Added public `stopAuthentication()` method** (`lib/shared/services/biometric_service.dart:117-120`)
   - Allows external callers to cancel ongoing authentication if needed

### Tests Added

6 new tests added to `test/shared/services/biometric_service_test.dart`:
- `should call stopAuthentication before starting new auth`
- `should handle authInProgress exception gracefully`
- `should handle userCanceled exception as failed`
- `should handle noBiometricsEnrolled exception as notAvailable`
- `concurrent auth calls should return same future instead of throwing`
- `stopAuthentication should call underlying stopAuthentication`

### Quality Checks

- ✅ Flutter analyze passed (no new issues in biometric_service.dart)
- ✅ All 30 biometric_service tests passing
- ✅ All project tests passing (exit code 0)

### Decisions Made

- Chose to return the existing completer's future for concurrent calls rather than blocking or throwing
- This ensures all callers get the same result without race conditions
- Did not modify `auth_providers.dart` as the service-level fix is sufficient
