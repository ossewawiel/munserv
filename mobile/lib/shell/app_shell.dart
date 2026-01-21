import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/messages/providers/messages_providers.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/branding_header.dart';
import '../shared/widgets/map_background.dart';

/// Navigation destinations for the bottom navigation bar
enum NavDestination {
  home('/'),
  issues('/issues'),
  messages('/messages'),
  profile('/profile');

  const NavDestination(this.path);
  final String path;
}

/// App shell with bottom navigation bar and vintage map background
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return Scaffold(
      body: Column(
        children: [
          const BrandingHeader(),
          Expanded(
            child: MapBackground(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.issues,
          ),
          NavigationDestination(
            icon: Badge(
              label: Text(unreadCount.toString()),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.mail_outline),
            ),
            selectedIcon: Badge(
              label: Text(unreadCount.toString()),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.mail),
            ),
            label: l10n.messages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
