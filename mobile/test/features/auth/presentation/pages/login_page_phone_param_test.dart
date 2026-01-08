import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage with phone parameter', () {
    test('LoginPage accepts optional phoneNumber parameter', () {
      // Verify the LoginPage constructor accepts phoneNumber
      const page = LoginPage(phoneNumber: '+27821234567');
      expect(page.phoneNumber, '+27821234567');
    });

    test('LoginPage phoneNumber can be null', () {
      // Verify the LoginPage works without phoneNumber
      const page = LoginPage();
      expect(page.phoneNumber, isNull);
    });

    test('LoginPage phoneNumber can be empty string', () {
      // Verify the LoginPage handles empty string
      const page = LoginPage(phoneNumber: '');
      expect(page.phoneNumber, '');
    });
  });
}
