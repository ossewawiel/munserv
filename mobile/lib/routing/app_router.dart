import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const _PlaceholderPage(title: 'Home'),
      ),
      GoRoute(
        path: '/auth/phone',
        name: 'phone',
        builder: (context, state) =>
            const _PlaceholderPage(title: 'Phone Entry'),
      ),
      GoRoute(
        path: '/auth/otp',
        name: 'otp',
        builder: (context, state) => const _PlaceholderPage(title: 'OTP Verify'),
      ),
      GoRoute(
        path: '/auth/pin-setup',
        name: 'pinSetup',
        builder: (context, state) => const _PlaceholderPage(title: 'PIN Setup'),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const _PlaceholderPage(title: 'Login'),
      ),
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
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const _PlaceholderPage(title: 'Profile'),
      ),
    ],
  );
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
