import 'package:flutter/material.dart';

import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/branding_header.dart';
import '../../../../shared/widgets/map_background.dart';

/// Common layout for authentication pages with vintage map background
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
      body: Column(
        children: [
          // Branding header at the top
          const BrandingHeader(),
          // Main content with map background
          Expanded(
            child: MapBackground(
              child: Column(
                children: [
                  // Optional back button row
                  if (showBackButton)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: onBack ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                  // Main content
                  Expanded(
                    child: SafeArea(
                      top: false, // BrandingHeader handles top safe area
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                              child: SingleChildScrollView(child: child),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
