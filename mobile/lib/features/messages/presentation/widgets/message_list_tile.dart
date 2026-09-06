import 'package:flutter/material.dart';

import '../../../../shared/models/message.dart';
import '../../../../shared/theme/typography.dart';

/// A list tile for displaying a message in the messages list.
class MessageListTile extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const MessageListTile({
    super.key,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = message.isUnread;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      leading: _buildIcon(colors),
      title: Text(
        message.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        message.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatRelativeTime(message.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: Spacing.xs),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildIcon(ColorScheme colors) {
    final (icon, color) = switch (message.type) {
      MessageType.groundAdminInvitation ||
      MessageType.groundAdminApplication => (Icons.person_add, Colors.blue),
      MessageType.verifyNewIssue ||
      MessageType.verifyFix => (Icons.fact_check, Colors.orange),
      MessageType.groundAdminApproved => (Icons.check_circle, Colors.green),
      MessageType.groundAdminDeclined ||
      MessageType.groundAdminRevocation => (Icons.cancel, Colors.red),
      MessageType.groundAdminInvitationDeclined => (
        Icons.person_off,
        Colors.orange,
      ),
      MessageType.groundAdminStepdownRequest => (
        Icons.exit_to_app,
        Colors.purple,
      ),
      MessageType.memberRegistration => (Icons.person_add, Colors.teal),
      MessageType.monthlyReport => (Icons.assessment, Colors.indigo),
      MessageType.adminWelcome => (Icons.celebration, Colors.green),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
