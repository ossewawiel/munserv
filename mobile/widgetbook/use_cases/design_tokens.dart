import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/theme/generated/tokens.dart';
import 'package:munserv_mobile/shared/theme/typography.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Renders the generated design tokens: colour scales and size scales.
///
/// Lives in `widgetbook/` (not `lib/`) because it exists only for the
/// catalogue; the tokens themselves come from
/// `lib/shared/theme/generated/tokens.dart`.
class DesignTokensShowcase extends StatelessWidget {
  const DesignTokensShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        _SectionTitle('Brand'),
        _ColorRow({
          'primary': TokensBrand.primary,
          'secondary': TokensBrand.secondary,
          'tertiary': TokensBrand.tertiary,
        }),
        _SectionTitle('Light scheme'),
        _ColorRow({
          'primary': TokensSchemeLight.primary,
          'secondary': TokensSchemeLight.secondary,
          'tertiary': TokensSchemeLight.tertiary,
          'surface': TokensSchemeLight.surface,
          'error': TokensSchemeLight.error,
        }),
        _SectionTitle('Dark scheme'),
        _ColorRow({
          'primary': TokensSchemeDark.primary,
          'secondary': TokensSchemeDark.secondary,
          'tertiary': TokensSchemeDark.tertiary,
          'surface': TokensSchemeDark.surface,
          'error': TokensSchemeDark.error,
        }),
        _SectionTitle('Issue state'),
        _ColorRow({
          'reported': TokensSemanticIssueState.reported,
          'confirmed': TokensSemanticIssueState.confirmed,
          'inProgress': TokensSemanticIssueState.inProgress,
          'fixed': TokensSemanticIssueState.fixed,
          'rejected': TokensSemanticIssueState.rejected,
          'reopened': TokensSemanticIssueState.reopened,
        }),
        _SectionTitle('Issue type'),
        _ColorRow({
          'pothole': TokensSemanticIssueType.pothole,
          'waterLeak': TokensSemanticIssueType.waterLeak,
          'sewageLeak': TokensSemanticIssueType.sewageLeak,
          'trafficLight': TokensSemanticIssueType.trafficLight,
          'streetLight': TokensSemanticIssueType.streetLight,
          'illegalDumping': TokensSemanticIssueType.illegalDumping,
          'other': TokensSemanticIssueType.other,
        }),
        _SectionTitle('Heat'),
        _ColorRow({
          'minimal': TokensSemanticHeat.minimal,
          'low': TokensSemanticHeat.low,
          'medium': TokensSemanticHeat.medium,
          'high': TokensSemanticHeat.high,
          'critical': TokensSemanticHeat.critical,
        }),
        _SectionTitle('Spacing'),
        _SizeRow({
          'xs': TokensSpacing.xs,
          'sm': TokensSpacing.sm,
          'md': TokensSpacing.md,
          'lg': TokensSpacing.lg,
          'xl': TokensSpacing.xl,
          'xxl': TokensSpacing.xxl,
        }),
        _SectionTitle('Radius'),
        _SizeRow({
          'sm': TokensRadius.sm,
          'md': TokensRadius.md,
          'lg': TokensRadius.lg,
          'xl': TokensRadius.xl,
        }, shape: BoxShape.rectangle),
        _SectionTitle('Icon size'),
        _SizeRow({
          'xs': TokensIconSize.xs,
          'sm': TokensIconSize.sm,
          'md': TokensIconSize.md,
          'lg': TokensIconSize.lg,
          'xl': TokensIconSize.xl,
          'xxl': TokensIconSize.xxl,
          'display': TokensIconSize.display,
        }, shape: BoxShape.circle),
        _SectionTitle('Thumbnail size'),
        _SizeRow({
          'sm': TokensThumbnailSize.sm,
          'md': TokensThumbnailSize.md,
          'lg': TokensThumbnailSize.lg,
          'xl': TokensThumbnailSize.xl,
        }, shape: BoxShape.rectangle),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final Map<String, Color> colors;

  const _ColorRow(this.colors);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.sm,
      children: colors.entries
          .map(
            (entry) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final Map<String, double> sizes;
  final BoxShape shape;

  const _SizeRow(this.sizes, {this.shape = BoxShape.circle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: sizes.entries
          .map(
            (entry) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: entry.value,
                  height: entry.value,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: shape,
                    borderRadius: shape == BoxShape.rectangle
                        ? BorderRadius.circular(4)
                        : null,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${entry.key} (${entry.value.toInt()})',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

@widgetbook.UseCase(name: 'Design/Tokens', type: DesignTokensShowcase)
Widget designTokens(BuildContext context) => const DesignTokensShowcase();
