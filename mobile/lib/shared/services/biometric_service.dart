import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_service.g.dart';

/// Service for handling biometric authentication
class BiometricService {
  final LocalAuthentication _auth;

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
  /// Returns true if authentication was successful
  Future<BiometricResult> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult.notAvailable();
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        return BiometricResult.success();
      } else {
        return BiometricResult.failed();
      }
    } catch (e) {
      return BiometricResult.error(e.toString());
    }
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
