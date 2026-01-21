import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/theme/typography.dart';

/// Action buttons displayed at the bottom of message detail.
class MessageActionButtons extends StatelessWidget {
  final Message message;
  final void Function(String action, String? note) onAction;
  final bool isLoading;

  const MessageActionButtons({
    super.key,
    required this.message,
    required this.onAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getActionsForType(context, message.actionType);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
              child: action.isPrimary
                  ? FilledButton(
                      onPressed: isLoading
                          ? null
                          : () => onAction(action.value, null),
                      child: isLoading && action.isPrimary
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(action.label),
                    )
                  : OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => onAction(action.value, null),
                      child: Text(action.label),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_ActionInfo> _getActionsForType(
    BuildContext context,
    String? actionType,
  ) {
    final l10n = S.of(context);

    return switch (actionType) {
      'accept_decline' => [
        _ActionInfo('accept', l10n.accept, true),
        _ActionInfo('decline', l10n.decline, false),
      ],
      'approve_reject' => [
        _ActionInfo('approve', l10n.approve, true),
        _ActionInfo('reject', l10n.reject, false),
      ],
      'confirm_verify' => [
        _ActionInfo('confirm', l10n.confirm, true),
        _ActionInfo('cannot_verify', l10n.cannotVerify, false),
      ],
      'acknowledge' => [_ActionInfo('dismiss', l10n.dismiss, true)],
      _ => [],
    };
  }
}

class _ActionInfo {
  final String value;
  final String label;
  final bool isPrimary;

  _ActionInfo(this.value, this.label, this.isPrimary);
}
