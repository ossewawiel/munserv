import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../providers/messages_providers.dart';
import '../widgets/widgets.dart';

/// Page displaying the user's message inbox.
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final messagesAsync = ref.watch(messagesProvider);
    final filter = ref.watch(messagesFilterStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.messages),
        centerTitle: false,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.filter,
            onSelected: (value) {
              ref
                  .read(messagesFilterStateProvider.notifier)
                  .setStatusFilter(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    if (filter.status == null)
                      const Icon(Icons.check, size: IconSizes.sm),
                    if (filter.status == null)
                      const SizedBox(width: Spacing.sm),
                    Text(l10n.all),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'unread',
                child: Row(
                  children: [
                    if (filter.status == 'unread')
                      const Icon(Icons.check, size: IconSizes.sm),
                    if (filter.status == 'unread')
                      const SizedBox(width: Spacing.sm),
                    Text(l10n.unread),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'actioned',
                child: Row(
                  children: [
                    if (filter.status == 'actioned')
                      const Icon(Icons.check, size: IconSizes.sm),
                    if (filter.status == 'actioned')
                      const SizedBox(width: Spacing.sm),
                    Text(l10n.actioned),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (response) {
          if (response.items.isEmpty) {
            return EmptyState.custom(
              icon: Icons.inbox_outlined,
              title: l10n.noMessages,
              subtitle: l10n.noMessagesSubtitle,
              actionLabel: l10n.refresh,
              onAction: () => ref.invalidate(messagesProvider),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(messagesProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              itemCount: response.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final message = response.items[index];
                return MessageListTile(
                  key: ValueKey(message.id),
                  message: message,
                  onTap: () => _openMessage(message),
                );
              },
            ),
          );
        },
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(messagesProvider),
        ),
      ),
    );
  }

  void _openMessage(Message message) {
    context.push('/messages/${message.id}');
  }
}
