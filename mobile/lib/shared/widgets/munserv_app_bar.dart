import 'package:flutter/material.dart';

import 'app_logo.dart';

/// Custom AppBar with centered MunServ logo
///
/// Replaces the standard text title with a logo.
/// Use this for main screens (home, issues list, profile).
class MunServAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Optional actions to display on the right side
  final List<Widget>? actions;

  /// Optional leading widget (defaults to back button when applicable)
  final Widget? leading;

  /// Whether to show the back button automatically
  final bool automaticallyImplyLeading;

  const MunServAppBar({
    super.key,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: const AppLogo.small(),
      centerTitle: true,
      actions: actions,
    );
  }
}
