import 'package:flutter/material.dart';

import '../../../../shared/theme/typography.dart';

/// Common layout for authentication pages
class AuthPageLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottomAction;
  final VoidCallback? onBack;
  final bool showBackButton;

  const AuthPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.bottomAction,
    this.onBack,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.of(context).pop(),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!showBackButton) const SizedBox(height: Spacing.xl),
              const SizedBox(height: Spacing.lg),
              // Header
              Text(
                title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: Spacing.xl),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
              // Bottom action
              if (bottomAction != null) ...[
                bottomAction!,
                SizedBox(
                  height: mediaQuery.padding.bottom > 0
                      ? Spacing.md
                      : Spacing.lg,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
