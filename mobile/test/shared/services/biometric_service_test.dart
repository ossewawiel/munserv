import 'dart:async';

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
        when(() => mockAuth.stopAuthentication()).thenAnswer((_) async => true);
        when(
          () => mockAuth.authenticate(
            localizedReason: 'Test reason',
            biometricOnly: true,
            persistAcrossBackgrounding: true,
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
        when(() => mockAuth.stopAuthentication()).thenAnswer((_) async => true);
        when(
          () => mockAuth.authenticate(
            localizedReason: 'Test reason',
            biometricOnly: true,
            persistAcrossBackgrounding: true,
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
        when(() => mockAuth.stopAuthentication()).thenAnswer((_) async => true);
        when(
          () => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            biometricOnly: any(named: 'biometricOnly'),
            sensitiveTransaction: any(named: 'sensitiveTransaction'),
            persistAcrossBackgrounding: any(
              named: 'persistAcrossBackgrounding',
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

      test('should call stopAuthentication before starting new auth', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(() => mockAuth.stopAuthentication()).thenAnswer((_) async => true);
        when(
          () => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            biometricOnly: any(named: 'biometricOnly'),
            sensitiveTransaction: any(named: 'sensitiveTransaction'),
            persistAcrossBackgrounding: any(
              named: 'persistAcrossBackgrounding',
            ),
          ),
        ).thenAnswer((_) async => true);

        // Act
        await service.authenticate(localizedReason: 'Test reason');

        // Assert
        verify(() => mockAuth.stopAuthentication()).called(1);
      });

      test('should handle authInProgress exception gracefully', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(() => mockAuth.stopAuthentication()).thenAnswer((_) async => true);
        when(
          () => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            biometricOnly: any(named: 'biometricOnly'),
            sensitiveTransaction: any(named: 'sensitiveTransaction'),
            persistAcrossBackgrounding: any(
              named: 'persistAcrossBackgrounding',
            ),
          ),
        ).thenThrow(
          const LocalAuthException(
            code: LocalAuthExceptionCode.authInProgress,
            description: 'Authentication already in progress',
          ),
        );

        // Act
        final result = await service.authenticate(
          localizedReason: 'Test reason',
        );

        // Assert
        expect(result.isError, isTrue);
        expect(result.errorMessage, contains('in progress'));
      });

      test('should handle userCanceled exception as failed', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => mockAuth.getAvailableBiometrics(),
        ).thenAnswer((_) async => [BiometricType.fingerprint]);
        when(() => mockAuth.stopAuthentication()).thenAnswer((_) async => true);
        when(
          () => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            biometricOnly: any(named: 'biometricOnly'),
            sensitiveTransaction: any(named: 'sensitiveTransaction'),
            persistAcrossBackgrounding: any(
              named: 'persistAcrossBackgrounding',
            ),
          ),
        ).thenThrow(
          const LocalAuthException(
            code: LocalAuthExceptionCode.userCanceled,
            description: 'User canceled',
          ),
        );

        // Act
        final result = await service.authenticate(
          localizedReason: 'Test reason',
        );

        // Assert
        expect(result.isFailed, isTrue);
      });

      test(
        'should handle noBiometricsEnrolled exception as notAvailable',
        () async {
          // Arrange
          when(
            () => mockAuth.isDeviceSupported(),
          ).thenAnswer((_) async => true);
          when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
          when(
            () => mockAuth.getAvailableBiometrics(),
          ).thenAnswer((_) async => [BiometricType.fingerprint]);
          when(
            () => mockAuth.stopAuthentication(),
          ).thenAnswer((_) async => true);
          when(
            () => mockAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              authMessages: any(named: 'authMessages'),
              biometricOnly: any(named: 'biometricOnly'),
              sensitiveTransaction: any(named: 'sensitiveTransaction'),
              persistAcrossBackgrounding: any(
                named: 'persistAcrossBackgrounding',
              ),
            ),
          ).thenThrow(
            const LocalAuthException(
              code: LocalAuthExceptionCode.noBiometricsEnrolled,
              description: 'No biometrics enrolled',
            ),
          );

          // Act
          final result = await service.authenticate(
            localizedReason: 'Test reason',
          );

          // Assert
          expect(result.isNotAvailable, isTrue);
        },
      );

      test(
        'concurrent auth calls should return same future instead of throwing',
        () async {
          // Arrange
          final completer = Completer<bool>();
          var authCallCount = 0;

          when(
            () => mockAuth.isDeviceSupported(),
          ).thenAnswer((_) async => true);
          when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
          when(
            () => mockAuth.getAvailableBiometrics(),
          ).thenAnswer((_) async => [BiometricType.fingerprint]);
          when(
            () => mockAuth.stopAuthentication(),
          ).thenAnswer((_) async => true);
          when(
            () => mockAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              authMessages: any(named: 'authMessages'),
              biometricOnly: any(named: 'biometricOnly'),
              sensitiveTransaction: any(named: 'sensitiveTransaction'),
              persistAcrossBackgrounding: any(
                named: 'persistAcrossBackgrounding',
              ),
            ),
          ).thenAnswer((_) {
            authCallCount++;
            return completer.future;
          });

          // Act - Start two auth calls concurrently
          final future1 = service.authenticate(localizedReason: 'Test 1');
          final future2 = service.authenticate(localizedReason: 'Test 2');

          // Complete the authentication
          completer.complete(true);

          final result1 = await future1;
          final result2 = await future2;

          // Assert - Both should succeed
          expect(result1.isSuccess, isTrue);
          expect(result2.isSuccess, isTrue);

          // But authenticate should only be called once
          expect(authCallCount, equals(1));
        },
      );
    });

    group('stopAuthentication', () {
      test('should call underlying stopAuthentication', () async {
        // Arrange
        when(() => mockAuth.stopAuthentication()).thenAnswer((_) async => true);

        // Act
        await service.stopAuthentication();

        // Assert
        verify(() => mockAuth.stopAuthentication()).called(1);
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
