import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/pages/pages.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/dev/presentation/pages/theme_showcase_page.dart';
import '../features/home/presentation/pages/pages.dart';
import '../features/issues/presentation/pages/pages.dart';
import '../features/profile/presentation/pages/pages.dart';
import '../shell/app_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);
  final storedPhoneAsync = ref.watch(storedPhoneNumberProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterRefreshStream(ref, authProvider),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final path = state.matchedLocation;

      // While checking auth status, don't redirect
      if (isLoading) return null;

      // Define auth routes
      const authRoutes = [
        '/auth/phone',
        '/auth/otp',
        '/auth/registration',
        '/auth/pin-setup',
        '/auth/login',
      ];

      final isOnAuthRoute = authRoutes.any((r) => path.startsWith(r));

      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isOnAuthRoute) {
        return '/';
      }

      // If not authenticated and not on auth route, redirect to auth
      if (!isAuthenticated && !isOnAuthRoute) {
        // Check if user has stored phone number to show login vs phone entry
        // If still loading, don't redirect yet - wait for value
        final redirectPath = storedPhoneAsync.when(
          data: (phone) => phone != null ? '/auth/login' : '/auth/phone',
          loading: () => null, // Don't redirect while loading
          error: (_, __) => '/auth/phone',
        );
        return redirectPath;
      }

      // No redirect needed
      return null;
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
        path: '/auth/phone',
        name: 'phone',
        builder: (context, state) => const PhoneEntryPage(),
      ),
      GoRoute(
        path: '/auth/otp',
        name: 'otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpVerifyPage(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/auth/registration',
        name: 'registration',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return RegistrationPage(
            phoneNumber: params['phone'] ?? '',
            tempToken: params['tempToken'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/auth/pin-setup',
        name: 'pinSetup',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return PinSetupPage(
            phoneNumber: params['phone'] ?? '',
            tempToken: params['tempToken'] ?? '',
            firstName: params['firstName'] ?? '',
            surname: params['surname'] ?? '',
            address: params['address'] ?? '',
            latitude: double.tryParse(params['latitude'] ?? '') ?? 0,
            longitude: double.tryParse(params['longitude'] ?? '') ?? 0,
            // Default sector for MVP - should be selected by user or auto-detected
            sectorId: params['sectorId'] ?? '550e8400-e29b-41d4-a716-446655440001',
          );
        },
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ===== Issue Detail Routes (outside shell for full-screen) =====
      GoRoute(
        path: '/issues/:id',
        name: 'issueDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return IssueDetailPage(issueId: id);
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

      // ===== Dev Routes (debug only) =====
      if (kDebugMode)
        GoRoute(
          path: '/dev/theme',
          name: 'themeShowcase',
          builder: (context, state) => const ThemeShowcasePage(),
        ),
    ],
  );
}

/// Listenable that refreshes GoRouter when auth state changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref, ProviderListenable provider) {
    ref.listen(provider, (prev, next) {
      notifyListeners();
    });
  }
}
