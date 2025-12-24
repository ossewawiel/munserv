import 'package:flutter/material.dart';

import '../../../../shared/theme/typography.dart';

/// A button with loading state
class LoadingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final ButtonStyle? style;
  final bool expand;

  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.style,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final button = FilledButton(
      onPressed: isLoading || !enabled ? null : onPressed,
      style: style ??
          FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
          ),
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Text(label),
    );

    return expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// An outlined button with loading state
class LoadingOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final ButtonStyle? style;
  final bool expand;

  const LoadingOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.style,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final button = OutlinedButton(
      onPressed: isLoading || !enabled ? null : onPressed,
      style: style ??
          OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
          ),
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          : Text(label),
    );

    return expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
