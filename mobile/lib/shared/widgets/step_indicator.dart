import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Progress indicator for multi-step wizards.
///
/// ## Usage
/// ```dart
/// StepIndicator(
///   totalSteps: 4,
///   currentStep: 2, // 0-indexed
///   labels: ['Photo', 'Type', 'Location', 'Review'],
/// )
/// ```
class StepIndicator extends StatelessWidget {
  /// Total number of steps.
  final int totalSteps;

  /// Current step (0-indexed).
  final int currentStep;

  /// Optional step labels.
  final List<String>? labels;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.labels,
  }) : assert(currentStep >= 0 && currentStep < totalSteps);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          // Even indices are steps, odd indices are connectors
          if (index.isOdd) {
            return _buildConnector(colors, index ~/ 2);
          } else {
            final stepIndex = index ~/ 2;
            return _buildStep(colors, textTheme, stepIndex);
          }
        }),
      ),
    );
  }

  Widget _buildStep(ColorScheme colors, TextTheme textTheme, int stepIndex) {
    final isCompleted = stepIndex < currentStep;
    final isCurrent = stepIndex == currentStep;
    final isActive = isCompleted || isCurrent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? colors.primary : colors.surfaceContainerHighest,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, size: IconSizes.sm, color: colors.onPrimary)
                : Text(
                    '${stepIndex + 1}',
                    style: textTheme.labelMedium?.copyWith(
                      color: isActive
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        if (labels != null && stepIndex < labels!.length) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            labels![stepIndex],
            style: textTheme.labelSmall?.copyWith(
              color: isActive ? colors.primary : colors.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnector(ColorScheme colors, int beforeIndex) {
    final isCompleted = beforeIndex < currentStep;

    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? colors.primary : colors.outlineVariant,
      ),
    );
  }
}
