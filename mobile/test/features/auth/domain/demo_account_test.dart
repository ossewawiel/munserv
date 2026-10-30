import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/demo_account.dart';

void main() {
  group('parseDemoAccounts', () {
    test('returns no accounts for an empty value', () {
      expect(parseDemoAccounts(''), isEmpty);
      expect(parseDemoAccounts('   '), isEmpty);
    });

    test('returns no accounts for invalid json', () {
      expect(parseDemoAccounts('{not json'), isEmpty);
    });

    test('returns no accounts when the value is not a list', () {
      expect(parseDemoAccounts('{"group": "member"}'), isEmpty);
    });

    test('drops an entry with an admin group', () {
      const raw =
          '[{"group":"pod_chief","name":"A","email":"a@example.test","password":"p"},'
          '{"group":"member","name":"B","email":"b@example.test","password":"p"},'
          '{"group":"member","name":"C","email":"c@example.test"}]';
      final accounts = parseDemoAccounts(raw);
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'B');
    });

    test('keeps valid entries in order', () {
      const raw =
          '[{"group":"ground_admin","name":"Sam","email":"s@example.test","password":"p1"},'
          '{"group":"member","name":"Jo","email":"j@example.test","password":"p2"}]';
      final accounts = parseDemoAccounts(raw);
      expect(accounts.map((a) => a.name), ['Sam', 'Jo']);
      expect(accounts.first.group, DemoAccountGroup.groundAdmin);
      expect(accounts.last.email, 'j@example.test');
      expect(accounts.last.password, 'p2');
    });
  });
}
