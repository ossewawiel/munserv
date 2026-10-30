import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/demo_account.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/quick_login_dropdown.dart';

import 'golden_test_helper.dart';

const _accounts = [
  DemoAccount(
    group: DemoAccountGroup.member,
    name: 'John',
    email: 'john@example.test',
    password: 'example-password',
  ),
  DemoAccount(
    group: DemoAccountGroup.member,
    name: 'Thandi',
    email: 'thandi@example.test',
    password: 'example-password',
  ),
  DemoAccount(
    group: DemoAccountGroup.groundAdmin,
    name: 'Sipho',
    email: 'sipho@example.test',
    password: 'example-password',
  ),
];

const _size = Size(390, 400);

Widget _dropdown() => Padding(
  padding: const EdgeInsets.all(24),
  child: Align(
    alignment: Alignment.topCenter,
    child: QuickLoginDropdown(accounts: _accounts, onSelected: (_) {}),
  ),
);

void main() {
  setUpAll(goldenTestSetUp);

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    group('QuickLoginDropdown $theme', () {
      testWidgets('closed', (tester) async {
        await pumpGolden(tester, _dropdown(), dark: dark, size: _size);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/quick_login_dropdown_closed_$theme.png'),
        );
      });

      testWidgets('open', (tester) async {
        await pumpGolden(tester, _dropdown(), dark: dark, size: _size);
        await tester.tap(find.byType(QuickLoginDropdown));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/quick_login_dropdown_open_$theme.png'),
        );
      });
    });
  }
}
