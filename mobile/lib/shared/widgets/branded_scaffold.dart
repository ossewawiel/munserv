import 'package:flutter/material.dart';

import 'branding_header.dart';

/// A Scaffold wrapper that includes the MunServ branding header at the top.
///
/// Use this instead of [Scaffold] to automatically include the branding header
/// above the AppBar on all screens.
///
/// Example:
/// ```dart
/// BrandedScaffold(
///   appBar: AppBar(title: Text('Issues')),
///   body: IssueList(),
/// )
/// ```
class BrandedScaffold extends StatelessWidget {
  /// The primary content of the scaffold.
  final Widget? body;

  /// An app bar to display at the top of the scaffold, below the branding header.
  final PreferredSizeWidget? appBar;

  /// A button displayed floating above [body], in the bottom right corner.
  final Widget? floatingActionButton;

  /// Location of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// A set of buttons that are displayed at the bottom of the scaffold.
  final Widget? bottomNavigationBar;

  /// The color of the [Material] widget that underlies the entire Scaffold.
  final Color? backgroundColor;

  /// Whether the [body] should size itself to avoid the window's bottom padding.
  final bool? resizeToAvoidBottomInset;

  /// A bottom sheet to display.
  final Widget? bottomSheet;

  /// A drawer to display.
  final Widget? drawer;

  /// An end drawer to display.
  final Widget? endDrawer;

  /// Whether to extend the body behind the app bar.
  final bool extendBodyBehindAppBar;

  /// Whether to extend the body to the bottom of the scaffold.
  final bool extendBody;

  const BrandedScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.bottomSheet,
    this.drawer,
    this.endDrawer,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomSheet: bottomSheet,
      drawer: drawer,
      endDrawer: endDrawer,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          const BrandingHeader(),
          if (appBar != null)
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: appBar!,
            ),
          Expanded(
            child: body ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
