import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:munserv_mobile/features/messages/providers/messages_providers.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';
import 'package:munserv_mobile/shell/app_shell.dart';

/// Mock UnreadCountNotifier for testing
class MockUnreadCountNotifier extends UnreadCountNotifier {
  @override
  Future<int> build() async => 0;
}

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Home Content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/issues',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Issues Content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/messages',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Messages Content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Profile Content')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        unreadCountProvider.overrideWith(MockUnreadCountNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: buildRouter(),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
      ),
    );
  }

  group('AppShell', () {
    testWidgets('displays bottom navigation bar with 4 destinations', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Verify NavigationBar exists
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify 4 destinations
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('shows navigation labels', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Verify navigation labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows home content initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Home Content'), findsOneWidget);
    });

    testWidgets('navigates to issues when issues tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Tap the second navigation destination (Issues)
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Issues Content'), findsOneWidget);
    });

    testWidgets('navigates to profile when profile tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Tap the fourth navigation destination (Profile)
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(3));
      await tester.pumpAndSettle();

      expect(find.text('Profile Content'), findsOneWidget);
    });

    testWidgets('preserves state when switching tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Start on home
      expect(find.text('Home Content'), findsOneWidget);

      // Go to issues
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Issues Content'), findsOneWidget);

      // Go back to home
      await tester.tap(destinations.at(0));
      await tester.pumpAndSettle();
      expect(find.text('Home Content'), findsOneWidget);
    });
  });
}
