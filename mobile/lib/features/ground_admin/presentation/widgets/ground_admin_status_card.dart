import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/ground_admin.dart';
import '../../../../shared/theme/typography.dart';

/// Card showing Ground Admin status and stats.
class GroundAdminStatusCard extends StatelessWidget {
  final GroundAdminInfo info;
  final VoidCallback? onStepDown;

  const GroundAdminStatusCard({super.key, required this.info, this.onStepDown});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
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
                Icon(Icons.verified_user, color: colors.primary),
                const SizedBox(width: Spacing.sm),
                Text(
                  l10n.groundAdminStatus,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                _buildStatusChip(context, info.status),
              ],
            ),
            const Divider(height: Spacing.lg),
            _buildStatRow(
              context,
              l10n.responseRate,
              info.formattedResponseRate,
            ),
            _buildStatRow(
              context,
              l10n.pendingVerifications,
              info.pendingVerifications.toString(),
            ),
            _buildStatRow(
              context,
              l10n.totalVerifications,
              info.totalVerifications.toString(),
            ),
            _buildStatRow(context, l10n.memberSince, _formatDate(info.since)),
            if (onStepDown != null) ...[
              const Divider(height: Spacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onStepDown,
                  child: Text(l10n.stepDownFromRole),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, GroundAdminStatus status) {
    final (color, label) = switch (status) {
      GroundAdminStatus.active => (Colors.green, 'Active'),
      GroundAdminStatus.onHold => (Colors.orange, 'On Hold'),
      GroundAdminStatus.inactive => (Colors.grey, 'Inactive'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
