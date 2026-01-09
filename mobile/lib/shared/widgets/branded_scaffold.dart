import 'package:flutter/material.dart';

import 'branding_header.dart';
import 'map_background.dart';

/// A Scaffold wrapper that includes the MunServ branding header at the top
/// and an optional vintage map background for the body content.
///
/// Use this instead of [Scaffold] to automatically include:
/// - Branding header above the AppBar
/// - Vintage map background on the body content (optional, enabled by default)
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

  /// Whether to show the vintage map background behind the body content.
  /// Defaults to true. Set to false for screens like maps that don't need it.
  final bool showMapBackground;

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
    this.showMapBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final bodyContent = body ?? const SizedBox.shrink();

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
            child: showMapBackground
                ? MapBackground(child: bodyContent)
                : bodyContent,
          ),
        ],
      ),
    );
  }
}
