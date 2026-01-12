import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// A standardized error banner for displaying form/API errors
///
/// Displays an error message with an icon, following M3 design patterns.
/// Optionally supports a dismiss button and entry animation.
///
/// Example:
/// ```dart
/// if (_errorText != null)
///   FormErrorBanner(
///     message: _errorText!,
///     onDismiss: () => setState(() => _errorText = null),
///   ),
/// ```
class FormErrorBanner extends StatefulWidget {
  /// The error message to display
  final String message;

  /// Optional callback when user dismisses the banner
  /// If null, no dismiss button is shown
  final VoidCallback? onDismiss;

  /// Whether to animate the banner appearance
  /// Defaults to true for a smooth entry effect
  final bool animate;

  const FormErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.animate = true,
  });

  @override
  State<FormErrorBanner> createState() => _FormErrorBannerState();
}

class _FormErrorBannerState extends State<FormErrorBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Semantics(
      label: 'Error: ${widget.message}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: Radii.mdRadius,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (widget.onDismiss != null) ...[
              const SizedBox(width: Spacing.sm),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(
                  Icons.close,
                  color: colorScheme.onErrorContainer,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!widget.animate) {
      return content;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: content),
    );
  }
}
