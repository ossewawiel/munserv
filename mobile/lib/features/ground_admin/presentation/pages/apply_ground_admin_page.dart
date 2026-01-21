import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../providers/ground_admin_providers.dart';

/// Page for members to apply to become a Ground Admin.
class ApplyGroundAdminPage extends ConsumerWidget {
  const ApplyGroundAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final actionState = ref.watch(groundAdminActionProvider);
    final isLoading = actionState is GroundAdminActionStateLoading;

    // Handle success state
    ref.listen(groundAdminActionProvider, (previous, next) {
      if (next is GroundAdminActionStateSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.applicationSubmitted)));
        context.pop();
      } else if (next is GroundAdminActionStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: colors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.becomeGroundAdmin)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(context, l10n),
            const SizedBox(height: Spacing.lg),
            _buildResponsibilitiesSection(context, l10n),
            const SizedBox(height: Spacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : () => _apply(context, ref),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.applyNow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, S l10n) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colors.primary),
                const SizedBox(width: Spacing.sm),
                Text(
                  l10n.whatIsGroundAdmin,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              l10n.groundAdminDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibilitiesSection(BuildContext context, S l10n) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.responsibilities, style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.md),
            _buildResponsibilityItem(
              context,
              Icons.fact_check,
              l10n.verifyNewIssues,
            ),
            _buildResponsibilityItem(
              context,
              Icons.check_circle,
              l10n.confirmFixes,
            ),
            _buildResponsibilityItem(
              context,
              Icons.camera_alt,
              l10n.providePhotoEvidence,
            ),
            _buildResponsibilityItem(
              context,
              Icons.schedule,
              l10n.respondPromptly,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibilityItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(icon, size: IconSizes.md, color: colors.onSurfaceVariant),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.onSurface)),
          ),
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    await ref.read(groundAdminActionProvider.notifier).apply();
  }
}
