import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/services/biometric_service.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../issues/providers/issue_providers.dart';
import '../../../issues/presentation/widgets/widgets.dart';

/// Home page showing dashboard overview
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _hasCheckedBiometric = false;

  @override
  void initState() {
    super.initState();
    // Check biometric offer after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricOffer();
    });
  }

  Future<void> _checkBiometricOffer() async {
    if (_hasCheckedBiometric) return;
    _hasCheckedBiometric = true;

    if (!mounted) return;

    // Cache ref reads before async gaps
    final biometricService = ref.read(biometricServiceProvider);

    final isBiometricEnabled = await ref.read(
      isBiometricLoginEnabledProvider.future,
    );

    if (!mounted) return;

    final biometricAvailable = await biometricService.isBiometricAvailable();

    if (!isBiometricEnabled && biometricAvailable && mounted) {
      await _offerBiometricSetup();
    }
  }

  Future<void> _offerBiometricSetup() async {
    if (!mounted) return;

    // Get the temporary PIN stored during login
    final tempPin = ref.read(tempPinForBiometricSetupProvider);
    if (tempPin == null) {
      return;
    }

    final l10n = S.of(context);
    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.useBiometrics),
        content: const Text(
          'Would you like to enable fingerprint or face unlock for faster login next time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    // Clear the temp PIN regardless of choice
    ref.read(tempPinForBiometricSetupProvider.notifier).clear();

    if (shouldEnable == true && mounted) {
      final biometricNotifier = ref.read(biometricLoginProvider.notifier);
      final result = await biometricNotifier.enableBiometric(tempPin);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric login enabled!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorOrNull?.displayMessage ??
                    'Could not enable biometrics',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final issuesAsync = ref.watch(issuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/map'),
            tooltip: l10n.mapViewTitle,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(issuesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Welcome section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.sm,
                  Spacing.lg,
                  Spacing.lg,
                ),
                child: Text(
                  'Here\'s what\'s happening in your area',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: _QuickActions(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: Spacing.lg)),

            // Recent issues header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Issues',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/issues'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // Recent issues list
            issuesAsync.when(
              data: (paginatedIssues) {
                final issues = paginatedIssues.items.take(5).toList();
                if (issues.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyState());
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final issue = issues[index];
                      return Padding(
                        key: ValueKey(issue.id),
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: IssueCard(
                          issue: issue,
                          onTap: () => context.push('/issues/${issue.id}'),
                        ),
                      );
                    }, childCount: issues.length),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Failed to load issues',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: Spacing.sm),
                      FilledButton(
                        onPressed: () => ref.invalidate(issuesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.xl)),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_circle_outline,
            label: 'Report Issue',
            color: theme.colorScheme.primary,
            onTap: () => context.push('/report'),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.list_alt,
            label: 'My Reports',
            color: theme.colorScheme.secondary,
            onTap: () => context.push('/my-issues'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacing.md),
          Text('No issues reported yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            'Be the first to report an issue in your area',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: () => context.push('/report'),
            icon: const Icon(Icons.add),
            label: const Text('Report Issue'),
          ),
        ],
      ),
    );
  }
}
