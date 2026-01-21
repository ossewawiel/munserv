import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../providers/ground_admin_providers.dart';

/// Page for members to accept or decline a Ground Admin invitation.
class InvitationResponsePage extends ConsumerWidget {
  final String applicationId;
  final String? inviterName;

  const InvitationResponsePage({
    super.key,
    required this.applicationId,
    this.inviterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final actionState = ref.watch(groundAdminActionProvider);
    final isLoading = actionState is GroundAdminActionStateLoading;

    // Handle state changes
    ref.listen(groundAdminActionProvider, (previous, next) {
      if (next is GroundAdminActionStateSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
        context.pop();
      } else if (next is GroundAdminActionStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: colors.error),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groundAdminInvitation)),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                        CircleAvatar(
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            Icons.person_add,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Text(
                            inviterName != null
                                ? l10n.invitedByAdmin(inviterName!)
                                : l10n.invitedToBeGroundAdmin,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      l10n.groundAdminInvitationDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            _buildBenefitsSection(context, l10n),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => _decline(context, ref),
                    child: Text(l10n.decline),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading ? null : () => _accept(context, ref),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.accept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context, S l10n) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.asGroundAdminYouWill, style: theme.textTheme.titleSmall),
            const SizedBox(height: Spacing.sm),
            _buildBenefitItem(context, l10n.verifyNewIssues),
            _buildBenefitItem(context, l10n.confirmFixes),
            _buildBenefitItem(context, l10n.helpYourCommunity),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, String text) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Icon(Icons.check, size: IconSizes.sm, color: colors.primary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    await ref
        .read(groundAdminActionProvider.notifier)
        .acceptInvitation(applicationId);
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    await ref
        .read(groundAdminActionProvider.notifier)
        .declineInvitation(applicationId);
  }
}
