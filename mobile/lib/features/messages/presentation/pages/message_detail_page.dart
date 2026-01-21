import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../providers/messages_providers.dart';
import '../widgets/widgets.dart';

/// Page displaying message detail with action buttons.
class MessageDetailPage extends ConsumerStatefulWidget {
  final String messageId;

  const MessageDetailPage({super.key, required this.messageId});

  @override
  ConsumerState<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends ConsumerState<MessageDetailPage> {
  bool _markedAsRead = false;

  @override
  void initState() {
    super.initState();
    // Mark as read when opened
    Future.microtask(_markAsRead);
  }

  Future<void> _markAsRead() async {
    if (_markedAsRead) return;
    _markedAsRead = true;

    final result = await ref
        .read(messageActionProvider.notifier)
        .markAsRead(widget.messageId);

    // Ignore errors for mark as read - not critical
    if (result.isFailure && mounted) {
      // Silently fail - the message was still read by the user
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final messageAsync = ref.watch(messageDetailProvider(widget.messageId));
    final actionState = ref.watch(messageActionProvider);
    final isLoading = actionState is MessageActionStateLoading;

    return BrandedScaffold(
      appBar: AppBar(title: Text(l10n.messageDetail)),
      body: messageAsync.when(
        data: (message) => _buildContent(context, message, isLoading),
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () =>
              ref.invalidate(messageDetailProvider(widget.messageId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Message message, bool isLoading) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message type badge
          _buildTypeBadge(context, message.type),
          const SizedBox(height: Spacing.md),

          // Title
          Text(message.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.sm),

          // Timestamp
          Text(
            _formatDateTime(message.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const Divider(height: Spacing.xl),

          // Body
          Text(message.body, style: theme.textTheme.bodyLarge),

          // Related entity link (if applicable)
          if (message.relatedEntityId != null &&
              message.relatedEntityType == 'issue') ...[
            const SizedBox(height: Spacing.lg),
            _buildRelatedIssueLink(context, message),
          ],

          const SizedBox(height: Spacing.xl),

          // Action buttons
          if (message.hasActions) ...[
            if (message.isVerificationMessage)
              _buildVerificationActions(context, message, isLoading)
            else
              MessageActionButtons(
                message: message,
                onAction: (action, note) =>
                    _handleAction(message, action, note),
                isLoading: isLoading,
              ),
          ] else if (message.status == MessageStatus.actioned) ...[
            _buildActionedStatus(context, message),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, MessageType type) {
    final (color, label) = switch (type) {
      MessageType.groundAdminInvitation => (Colors.blue, 'Invitation'),
      MessageType.groundAdminApplication => (Colors.blue, 'Application'),
      MessageType.verifyNewIssue => (Colors.orange, 'Verification Request'),
      MessageType.verifyFix => (Colors.orange, 'Fix Verification'),
      MessageType.groundAdminApproved => (Colors.green, 'Approved'),
      MessageType.groundAdminDeclined => (Colors.red, 'Declined'),
      MessageType.groundAdminRevocation => (Colors.red, 'Revoked'),
      MessageType.groundAdminInvitationDeclined => (Colors.orange, 'Declined'),
      MessageType.groundAdminStepdownRequest => (Colors.purple, 'Step Down'),
      MessageType.memberRegistration => (Colors.teal, 'Registration'),
      MessageType.monthlyReport => (Colors.indigo, 'Report'),
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

  Widget _buildRelatedIssueLink(BuildContext context, Message message) {
    final l10n = S.of(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: const Icon(Icons.report_problem),
        title: Text(l10n.viewRelatedIssue),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/issues/${message.relatedEntityId}'),
      ),
    );
  }

  Widget _buildVerificationActions(
    BuildContext context,
    Message message,
    bool isLoading,
  ) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isLoading
              ? null
              : () => _navigateToVerification(context, message),
          icon: const Icon(Icons.fact_check),
          label: Text(l10n.verifyNow),
        ),
      ],
    );
  }

  void _navigateToVerification(BuildContext context, Message message) {
    final verificationType = message.type == MessageType.verifyNewIssue
        ? 'existence'
        : 'fix';
    context.push('/verify/${message.relatedEntityId}?type=$verificationType');
  }

  Widget _buildActionedStatus(BuildContext context, Message message) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;

    final actionLabel = switch (message.actionResult) {
      'accepted' => l10n.accepted,
      'declined' => l10n.declined,
      'approved' => l10n.approved,
      'rejected' => l10n.rejected,
      'confirmed' => l10n.confirmed,
      'dismissed' => l10n.dismissed,
      _ => message.actionResult ?? l10n.actioned,
    };

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.primary),
          const SizedBox(width: Spacing.sm),
          Text(
            '${l10n.actionTaken}: $actionLabel',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    Message message,
    String action,
    String? note,
  ) async {
    final result = await ref
        .read(messageActionProvider.notifier)
        .performAction(message.id, action, note: note);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).actionCompleted)));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull?.displayMessage ?? 'Error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }
}
