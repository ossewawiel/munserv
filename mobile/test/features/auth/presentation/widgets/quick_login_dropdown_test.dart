import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/features/auth/domain/demo_account.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/quick_login_dropdown.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';

const _accounts = [
  DemoAccount(
    group: DemoAccountGroup.member,
    name: 'John',
    email: 'john@example.test',
    password: 'pw1',
  ),
  DemoAccount(
    group: DemoAccountGroup.groundAdmin,
    name: 'Sipho',
    email: 'sipho@example.test',
    password: 'pw2',
  ),
  DemoAccount(
    group: DemoAccountGroup.groundAdmin,
    name: '',
    email: 'anon@example.test',
    password: 'pw3',
  ),
];

Widget _host({
  required ValueChanged<DemoAccount> onSelected,
  bool enabled = true,
}) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: QuickLoginDropdown(
        accounts: _accounts,
        onSelected: onSelected,
        enabled: enabled,
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(QuickLoginDropdown));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows member and ground admin headings', (tester) async {
    await tester.pumpWidget(_host(onSelected: (_) {}));
    await _open(tester);

    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Ground admin'), findsWidgets);
  });

  testWidgets('reads role then name', (tester) async {
    await tester.pumpWidget(_host(onSelected: (_) {}));
    await _open(tester);

    expect(find.text('Member · John'), findsOneWidget);
    expect(find.text('Ground admin · Sipho'), findsOneWidget);
  });

  testWidgets('calls onSelected with the chosen account', (tester) async {
    DemoAccount? picked;
    await tester.pumpWidget(_host(onSelected: (a) => picked = a));
    await _open(tester);

    await tester.tap(find.text('Ground admin · Sipho'));
    await tester.pumpAndSettle();

    expect(picked, _accounts[1]);
  });

  testWidgets('does nothing when disabled', (tester) async {
    DemoAccount? picked;
    await tester.pumpWidget(
      _host(onSelected: (a) => picked = a, enabled: false),
    );
    await tester.tap(find.byType(QuickLoginDropdown), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Member · John'), findsNothing);
    expect(picked, isNull);
  });
}
