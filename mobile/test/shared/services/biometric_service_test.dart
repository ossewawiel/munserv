import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:munserv_mobile/shared/services/biometric_service.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuthentication mockAuth;
  late BiometricService service;

  setUp(() {
    mockAuth = MockLocalAuthentication();
    service = BiometricService(mockAuth);
  });

  group('BiometricService', () {
    group('isDeviceSupported', () {
      test('should return true when device supports biometrics', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

        // Act
        final result = await service.isDeviceSupported();

        // Assert
        expect(result, isTrue);
        verify(() => mockAuth.isDeviceSupported()).called(1);
      });

      test(
        'should return false when device does not support biometrics',
        () async {
          // Arrange
          when(
            () => mockAuth.isDeviceSupported(),
          ).thenAnswer((_) async => false);

          // Act
          final result = await service.isDeviceSupported();

          // Assert
          expect(result, isFalse);
        },
      );
    });

    group('canCheckBiometrics', () {
      test('should return true when biometrics can be checked', () async {
        // Arrange
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);

        // Act
        final result = await service.canCheckBiometrics();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when biometrics cannot be checked', () async {
        // Arrange
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);

        // Act
        final result = await service.canCheckBiometrics();

        // Assert
        expect(result, isFalse);
      });

      test('should return false on exception', () async {
        // Arrange
        when(() => mockAuth.canCheckBiometrics).thenThrow(Exception('Error'));

        // Act
        final result = await service.canCheckBiometrics();

        // Assert
        expect(result, isFalse);
      });
    });

    group('getAvailableBiometrics', () {
      test('should return list of available biometrics', () async {
        // Arrange
        when(() => mockAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint, BiometricType.face],
        );

        // Act
        final result = await service.getAvailableBiometrics();

        // Assert
        expect(result, hasLength(2));
        expect(result, contains(BiometricType.fingerprint));
        expect(result, contains(BiometricType.face));
      });

      test('should return empty list on exception', () async {
        // Arrange
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenThrow(Exception('Error'));

        // Act
        final result = await service.getAvailableBiometrics();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('isBiometricAvailable', () {
      test(
        'should return true when device and biometrics are available',
        () async {
          // Arrange
          when(
            () => mockAuth.isDeviceSupported(),
          ).thenAnswer((_) async => true);
          when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
          when(
            () => mockAuth.getAvailableBiometrics(),
          ).thenAnswer((_) async => [BiometricType.fingerprint]);

          // Act
          final result = await service.isBiometricAvailable();

          // Assert
          expect(result, isTrue);
        },
      );

      test('should return false when device not supported', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await service.isBiometricAvailable();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when cannot check biometrics', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);

        // Act
        final result = await service.isBiometricAvailable();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when no biometrics enrolled', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => []);

        // Act
        final result = await service.isBiometricAvailable();

        // Assert
        expect(result, isFalse);
      });
    });

    group('authenticate', () {
      test('should return success when authentication succeeds', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(
          () => mockAuth.authenticate(
            localizedReason: 'Test reason',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          ),
        ).thenAnswer((_) async => true);

        // Act
        final result = await service.authenticate(
          localizedReason: 'Test reason',
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should return failed when authentication fails', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(
          () => mockAuth.authenticate(
            localizedReason: 'Test reason',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          ),
        ).thenAnswer((_) async => false);

        // Act
        final result = await service.authenticate(
          localizedReason: 'Test reason',
        );

        // Assert
        expect(result.isFailed, isTrue);
      });

      test(
        'should return notAvailable when biometrics not available',
        () async {
          // Arrange
          when(
            () => mockAuth.isDeviceSupported(),
          ).thenAnswer((_) async => false);

          // Act
          final result = await service.authenticate(
            localizedReason: 'Test reason',
          );

          // Assert
          expect(result.isNotAvailable, isTrue);
        },
      );

      test('should return error when exception occurs', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(
          () => mockAuth.authenticate(
            localizedReason: 'Test reason',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          ),
        ).thenThrow(Exception('Auth error'));

        // Act
        final result = await service.authenticate(
          localizedReason: 'Test reason',
        );

        // Assert
        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('Auth error'));
      });
    });

    group('getBiometricDescription', () {
      test(
        'should return Fingerprint when only fingerprint available',
        () async {
          // Arrange
          when(
            () => mockAuth.getAvailableBiometrics(),
          ).thenAnswer((_) async => [BiometricType.fingerprint]);

          // Act
          final result = await service.getBiometricDescription();

          // Assert
          expect(result, 'Fingerprint');
        },
      );

      test('should return Face ID when only face available', () async {
        // Arrange
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.face]);

        // Act
        final result = await service.getBiometricDescription();

        // Assert
        expect(result, 'Face ID');
      });

      test('should return Fingerprint or Face when both available', () async {
        // Arrange
        when(() => mockAuth.getAvailableBiometrics()).thenAnswer(
          (_) async => [BiometricType.fingerprint, BiometricType.face],
        );

        // Act
        final result = await service.getBiometricDescription();

        // Assert
        expect(result, 'Fingerprint or Face');
      });

      test('should return No biometrics available when empty', () async {
        // Arrange
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => []);

        // Act
        final result = await service.getBiometricDescription();

        // Assert
        expect(result, 'No biometrics available');
      });

      test('should return Fingerprint when strong biometric type', () async {
        // Arrange
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.strong]);

        // Act
        final result = await service.getBiometricDescription();

        // Assert
        expect(result, 'Fingerprint');
      });
    });

    group('BiometricResult', () {
      test('success result should have correct properties', () {
        final result = BiometricResult.success();
        expect(result.isSuccess, isTrue);
        expect(result.isFailed, isFalse);
        expect(result.isNotAvailable, isFalse);
        expect(result.isError, isFalse);
        expect(result.errorMessage, isNull);
      });

      test('failed result should have correct properties', () {
        final result = BiometricResult.failed();
        expect(result.isSuccess, isFalse);
        expect(result.isFailed, isTrue);
        expect(result.isNotAvailable, isFalse);
        expect(result.isError, isFalse);
        expect(result.errorMessage, isNull);
      });

      test('notAvailable result should have correct properties', () {
        final result = BiometricResult.notAvailable();
        expect(result.isSuccess, isFalse);
        expect(result.isFailed, isFalse);
        expect(result.isNotAvailable, isTrue);
        expect(result.isError, isFalse);
        expect(result.errorMessage, isNull);
      });

      test('error result should have correct properties', () {
        final result = BiometricResult.error('Test error');
        expect(result.isSuccess, isFalse);
        expect(result.isFailed, isFalse);
        expect(result.isNotAvailable, isFalse);
        expect(result.isError, isTrue);
        expect(result.errorMessage, 'Test error');
      });
    });
  });
}
