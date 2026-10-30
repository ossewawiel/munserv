import 'package:flutter/material.dart';
import 'package:munserv_mobile/features/auth/domain/demo_account.dart';
import 'package:munserv_mobile/features/auth/presentation/widgets/quick_login_dropdown.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _fakeAccounts = [
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

@widgetbook.UseCase(name: 'Default', type: QuickLoginDropdown)
Widget quickLoginDropdown(BuildContext context) {
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);

  return Padding(
    padding: const EdgeInsets.all(16),
    child: QuickLoginDropdown(
      accounts: _fakeAccounts,
      enabled: enabled,
      onSelected: (_) {},
    ),
  );
}
