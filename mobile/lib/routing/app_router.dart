import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/pages/pages.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/ground_admin/presentation/pages/pages.dart';
import '../features/home/presentation/pages/pages.dart';
import '../features/issues/presentation/pages/pages.dart';
import '../features/messages/presentation/pages/pages.dart';
import '../features/profile/presentation/pages/pages.dart';
import '../features/verification/presentation/pages/pages.dart';
import '../shell/app_shell.dart';

part 'app_router.g.dart';

/// Routes that don't require authentication
const _publicRoutes = {'/auth/login', '/auth/pin-login'};

/// Routes for authentication flow (intermediate states)
const _authFlowRoutes = {
  '/auth/login',
  '/auth/pin-login',
  '/auth/change-password',
  '/auth/pin-setup',
};

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);
  final quickLoginEligible = ref.watch(quickLoginEligibilityProvider);

  // Determine initial location based on auth state and quick login eligibility
  String initialLocation;
  if (authState.isAuthenticated) {
    initialLocation = '/';
  } else if (quickLoginEligible == true) {
    initialLocation = '/auth/pin-login';
  } else {
    initialLocation = '/auth/login';
  }

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _GoRouterRefreshStream(ref, [
      authProvider,
      quickLoginEligibilityProvider,
    ]),
    redirect: (context, state) {
      final path = state.matchedLocation;

      // Handle redirects based on auth state using pattern matching
      return switch (authState) {
        // Loading - stay on current route
        AuthStateLoading() || AuthStateInitial() => null,

        // Fully authenticated - redirect to home if on auth routes
        AuthStateAuthenticated() when _authFlowRoutes.contains(path) => '/',

        // Must change password - force to password change screen
        AuthStateMustChangePassword() when path != '/auth/change-password' =>
          '/auth/change-password',

        // Pending PIN setup - force to PIN setup screen
        AuthStatePendingPinSetup() when path != '/auth/pin-setup' =>
          '/auth/pin-setup',

        // User on email login but eligible for quick login - redirect to PIN login
        AuthStateUnauthenticated()
            when path == '/auth/login' && quickLoginEligible == true =>
          '/auth/pin-login',

        // Not authenticated and not on public route - redirect to appropriate login
        AuthStateUnauthenticated() when !_publicRoutes.contains(path) =>
          quickLoginEligible == true ? '/auth/pin-login' : '/auth/login',

        // Error state - redirect to login
        AuthStateError() when !_publicRoutes.contains(path) => '/auth/login',

        // No redirect needed
        _ => null,
      };
    },
    routes: [
      // ===== App Shell with Bottom Navigation =====
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),

          // Issues branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/issues',
                name: 'issues',
                builder: (context, state) => const IssueListPage(),
              ),
            ],
          ),

          // Messages branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                name: 'messages',
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),

          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ===== Auth Routes (outside shell) =====
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const EmailLoginPage(),
      ),
      GoRoute(
        path: '/auth/pin-login',
        name: 'pinLogin',
        builder: (context, state) => const PinLoginPage(),
      ),
      GoRoute(
        path: '/auth/change-password',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/auth/pin-setup',
        name: 'pinSetup',
        builder: (context, state) => const PinSetupEmailPage(),
      ),

      // ===== Issue Detail Routes (outside shell for full-screen) =====
      GoRoute(
        path: '/issues/:id',
        name: 'issueDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          // GoRouter guarantees 'id' exists for this route pattern
          assert(id != null, 'Issue ID is required');
          return IssueDetailPage(issueId: id ?? '');
        },
      ),
      GoRoute(
        path: '/issues/:id/map',
        name: 'issueMap',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FullscreenMapPage(issueId: id);
        },
      ),
      GoRoute(
        path: '/issues/:id/photos',
        name: 'issuePhotos',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final indexStr = state.uri.queryParameters['index'] ?? '0';
          final index = int.tryParse(indexStr) ?? 0;
          return PhotoGalleryPage(issueId: id, initialIndex: index);
        },
      ),
      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) => const ReportIssuePage(),
      ),
      GoRoute(
        path: '/my-issues',
        name: 'myIssues',
        builder: (context, state) => const MyReportsPage(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const IssueMapPage(),
      ),

      // ===== Messages Routes (outside shell for full-screen) =====
      GoRoute(
        path: '/messages/:id',
        name: 'messageDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MessageDetailPage(messageId: id);
        },
      ),

      // ===== Ground Admin Routes =====
      GoRoute(
        path: '/ground-admin/apply',
        name: 'applyGroundAdmin',
        builder: (context, state) => const ApplyGroundAdminPage(),
      ),
      GoRoute(
        path: '/ground-admin/invitation/:applicationId',
        name: 'groundAdminInvitation',
        builder: (context, state) {
          final applicationId = state.pathParameters['applicationId']!;
          final inviterName = state.uri.queryParameters['inviter'];
          return InvitationResponsePage(
            applicationId: applicationId,
            inviterName: inviterName,
          );
        },
      ),

      // ===== Verification Routes =====
      GoRoute(
        path: '/verify/:issueId',
        name: 'verifyIssue',
        builder: (context, state) {
          final issueId = state.pathParameters['issueId']!;
          final verificationType =
              state.uri.queryParameters['type'] ?? 'existence';
          return VerifyIssuePage(
            issueId: issueId,
            verificationType: verificationType,
          );
        },
      ),
    ],
  );
}

/// Listenable that refreshes GoRouter when auth state or quick login eligibility changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref, List<ProviderListenable> providers) {
    for (final provider in providers) {
      ref.listen(provider, (prev, next) {
        notifyListeners();
      });
    }
  }
}
