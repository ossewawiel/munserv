import 'package:flutter/material.dart';

/// A button with loading state
/// Follows Material Design 3 specifications:
/// - 40dp minimum height
/// - 48dp touch target (via MaterialTapTargetSize.padded)
/// - Stadium shape (pill)
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
      style:
          style ??
          FilledButton.styleFrom(
            minimumSize: const Size(64, 40), // M3 spec: 40dp height
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Text(label),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// An outlined button with loading state
/// Follows Material Design 3 specifications:
/// - 40dp minimum height
/// - 48dp touch target (via MaterialTapTargetSize.padded)
/// - Stadium shape (pill)
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
      style:
          style ??
          OutlinedButton.styleFrom(
            minimumSize: const Size(64, 40), // M3 spec: 40dp height
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          : Text(label),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
