import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../domain/demo_account.dart';

/// Dropdown of demo accounts for the email login page, grouped under Member
/// and Ground admin headings. Only built when the app carries demo accounts.
class QuickLoginDropdown extends StatelessWidget {
  final List<DemoAccount> accounts;
  final ValueChanged<DemoAccount> onSelected;
  final bool enabled;

  const QuickLoginDropdown({
    super.key,
    required this.accounts,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final headingStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(Spacing.xl)),
      foregroundColor: WidgetStatePropertyAll(colors.onSurfaceVariant),
      textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    );

    String roleOf(DemoAccountGroup group) => switch (group) {
      DemoAccountGroup.member => l10n.quickLoginGroupMember,
      DemoAccountGroup.groundAdmin => l10n.quickLoginGroupGroundAdmin,
    };

    final entries = <DropdownMenuEntry<DemoAccount>>[];
    for (final group in DemoAccountGroup.values) {
      final inGroup = accounts.where((a) => a.group == group).toList();
      if (inGroup.isEmpty) continue;
      final role = roleOf(group);
      final heading = DemoAccount(
        group: group,
        name: '',
        email: '',
        password: '',
      );
      entries.add(
        DropdownMenuEntry<DemoAccount>(
          value: heading,
          label: role,
          enabled: false,
          labelWidget: Text(role),
          style: headingStyle,
        ),
      );
      for (final account in inGroup) {
        final label = account.name.isEmpty
            ? role
            : l10n.quickLoginOption(role, account.name);
        entries.add(
          DropdownMenuEntry<DemoAccount>(value: account, label: label),
        );
      }
    }

    return DropdownMenu<DemoAccount>(
      expandedInsets: EdgeInsets.zero,
      enabled: enabled,
      label: Text(l10n.quickLoginLabel),
      leadingIcon: const Icon(Icons.person_outline),
      dropdownMenuEntries: entries,
      onSelected: (account) {
        if (account != null) onSelected(account);
      },
    );
  }
}
