import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:munserv_mobile/l10n/app_localizations.dart';
import 'package:munserv_mobile/shell/app_shell.dart';

void main() {
  GoRouter _buildRouter() {
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

  group('AppShell', () {
    testWidgets('displays bottom navigation bar with 3 destinations', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildRouter(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      );

      await tester.pump();

      // Verify NavigationBar exists
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify 3 destinations
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });

    testWidgets('shows navigation labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildRouter(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      );

      await tester.pump();

      // Verify navigation labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows home content initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildRouter(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      );

      await tester.pump();

      expect(find.text('Home Content'), findsOneWidget);
    });

    testWidgets('navigates to issues when issues tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildRouter(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      );

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
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildRouter(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      );

      await tester.pump();

      // Tap the third navigation destination (Profile)
      final destinations = find.byType(NavigationDestination);
      await tester.tap(destinations.at(2));
      await tester.pumpAndSettle();

      expect(find.text('Profile Content'), findsOneWidget);
    });

    testWidgets('preserves state when switching tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildRouter(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      );

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
