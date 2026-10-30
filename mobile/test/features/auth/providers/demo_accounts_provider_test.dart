import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/providers/demo_accounts_provider.dart';

void main() {
  test('is empty when the app is built without the define', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(demoAccountsProvider), isEmpty);
  });
}
