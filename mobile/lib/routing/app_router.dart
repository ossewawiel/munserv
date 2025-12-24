import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/pages/pages.dart';
import '../features/auth/providers/auth_providers.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);

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
        // Check if user has stored credentials to show login vs phone entry
        // For now, always go to phone entry
        return '/auth/phone';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // ===== Home/Main Routes =====
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const _PlaceholderPage(title: 'Home'),
      ),

      // ===== Auth Routes =====
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
          );
        },
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ===== Issue Routes =====
      GoRoute(
        path: '/issues',
        name: 'issues',
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Issue List'),
      ),
      GoRoute(
        path: '/issues/:id',
        name: 'issueDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _PlaceholderPage(title: 'Issue $id');
        },
      ),
      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Report Issue'),
      ),
      GoRoute(
        path: '/my-issues',
        name: 'myIssues',
        builder: (context, state) =>
            const _PlaceholderPage(title: 'My Issues'),
      ),

      // ===== Profile Routes =====
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const _PlaceholderPage(title: 'Profile'),
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

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Placeholder)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
