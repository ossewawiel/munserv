import 'dart:async';

import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_service.g.dart';

/// Service for handling biometric authentication
class BiometricService {
  final LocalAuthentication _auth;
  bool _isAuthenticating = false;
  Completer<BiometricResult>? _authCompleter;

  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  /// Check if device supports any form of local authentication
  Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported();
  }

  /// Check if biometrics are available and enrolled
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types on this device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric authentication is available
  /// Returns true if device supports biometrics AND has them enrolled
  Future<bool> isBiometricAvailable() async {
    final deviceSupported = await isDeviceSupported();
    if (!deviceSupported) return false;

    final canCheck = await canCheckBiometrics();
    if (!canCheck) return false;

    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  /// Authenticate using biometrics
  /// Returns the result of the authentication attempt.
  /// If authentication is already in progress, waits for it to complete
  /// and returns the same result.
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
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );

      final result =
          didAuthenticate ? BiometricResult.success() : BiometricResult.failed();
      _authCompleter!.complete(result);
      return result;
    } on LocalAuthException catch (e) {
      // Handle specific LocalAuth exceptions
      final result = switch (e.code) {
        LocalAuthExceptionCode.authInProgress =>
          BiometricResult.error('Authentication already in progress'),
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricResult.notAvailable(),
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricResult.failed(),
        _ => BiometricResult.error(e.description ?? 'Authentication failed'),
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
    await _auth.stopAuthentication();
  }

  /// Get a human-readable description of available biometrics
  Future<String> getBiometricDescription() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'No biometrics available';
    }

    final hasFingerprint =
        biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong);
    final hasFace = biometrics.contains(BiometricType.face);

    if (hasFingerprint && hasFace) {
      return 'Fingerprint or Face';
    } else if (hasFingerprint) {
      return 'Fingerprint';
    } else if (hasFace) {
      return 'Face ID';
    } else {
      return 'Biometrics';
    }
  }
}

/// Result of a biometric authentication attempt
sealed class BiometricResult {
  const BiometricResult();

  factory BiometricResult.success() = BiometricSuccess;
  factory BiometricResult.failed() = BiometricFailed;
  factory BiometricResult.notAvailable() = BiometricNotAvailable;
  factory BiometricResult.error(String message) = BiometricError;

  bool get isSuccess => this is BiometricSuccess;
  bool get isFailed => this is BiometricFailed;
  bool get isNotAvailable => this is BiometricNotAvailable;
  bool get isError => this is BiometricError;

  String? get errorMessage => switch (this) {
    BiometricError(:final message) => message,
    _ => null,
  };
}

class BiometricSuccess extends BiometricResult {
  const BiometricSuccess();
}

class BiometricFailed extends BiometricResult {
  const BiometricFailed();
}

class BiometricNotAvailable extends BiometricResult {
  const BiometricNotAvailable();
}

class BiometricError extends BiometricResult {
  final String message;
  const BiometricError(this.message);
}

/// Provider for BiometricService
@riverpod
BiometricService biometricService(Ref ref) {
  return BiometricService();
}

/// Provider for checking if biometrics are available
@riverpod
Future<bool> isBiometricAvailable(Ref ref) async {
  final service = ref.watch(biometricServiceProvider);
  return service.isBiometricAvailable();
}
