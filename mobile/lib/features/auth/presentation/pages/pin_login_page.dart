import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/pin_input_field.dart';

/// PIN login page for quick access
/// Shows when user has previously logged in and has PIN + credentials saved
class PinLoginPage extends ConsumerStatefulWidget {
  const PinLoginPage({super.key});

  @override
  ConsumerState<PinLoginPage> createState() => _PinLoginPageState();
}

class _PinLoginPageState extends ConsumerState<PinLoginPage> {
  final _pinKey = GlobalKey<PinInputFieldState>();

  bool _isLoading = false;
  String? _errorText;
  String? _userEmail;
  bool _biometricAttempted = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Schedule biometric prompt after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometricLogin();
    });
  }

  Future<void> _loadUserInfo() async {
    final storage = ref.read(secureStorageProvider);
    final email = await storage.getEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
      });
    }
  }

  Future<void> _attemptBiometricLogin() async {
    if (_biometricAttempted) return;
    _biometricAttempted = true;

    // Check if biometric is enabled
    final isBiometricEnabled = await ref.read(
      isBiometricLoginEnabledProvider.future,
    );
    if (!isBiometricEnabled || !mounted) return;

    // Attempt biometric authentication
    final biometricNotifier = ref.read(biometricLoginProvider.notifier);
    final result = await biometricNotifier.authenticateAndGetPin();

    if (!mounted) return;

    result.when(
      success: (pin) async {
        // PIN obtained from biometric - perform login
        await _performQuickLogin(pin);
      },
      failure: (error) {
        // Biometric failed or cancelled - user can enter PIN manually
        // Don't show error for biometric cancellation
        if (error.displayMessage.contains('cancelled') ||
            error.displayMessage.contains('failed')) {
          return;
        }
        setState(() {
          _errorText = error.displayMessage;
        });
      },
    );
  }

  Future<void> _onPinEntered(String pin) async {
    if (_isLoading) return;
    await _performQuickLogin(pin);
  }

  Future<void> _performQuickLogin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.quickLoginWithPin(pin);

    if (!mounted) return;

    result.when(
      success: (_) {
        // Navigation handled by router
      },
      failure: (error) {
        setState(() {
          _isLoading = false;
          _errorText = error.displayMessage;
        });
        _pinKey.currentState?.clear();
      },
    );
  }

  void _useDifferentAccount() {
    // Mark quick login as not eligible so router doesn't redirect back here
    ref.read(quickLoginEligibilityProvider.notifier).markNotEligible();
    // Navigate to email login
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: l10n.loginTitle,
      subtitle: _userEmail != null
          ? l10n.pinLoginSubtitle(_userEmail!)
          : l10n.loginSubtitle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: Spacing.xl),

          // PIN Input
          if (_isLoading)
            const CircularProgressIndicator()
          else
            PinInputField(
              key: _pinKey,
              onCompleted: _onPinEntered,
              autoFocus: true,
              errorText: _errorText,
            ),

          const SizedBox(height: Spacing.xl),

          // Biometric button (if available)
          Consumer(
            builder: (context, ref, child) {
              final biometricAsync = ref.watch(isBiometricLoginEnabledProvider);
              return biometricAsync.when(
                data: (isEnabled) {
                  if (!isEnabled) return const SizedBox.shrink();
                  return Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                _biometricAttempted = false;
                                _attemptBiometricLogin();
                              },
                        icon: const Icon(Icons.fingerprint),
                        label: Text(l10n.useBiometrics),
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) {
                  debugPrint('Biometric check error: $e\n$s');
                  return const SizedBox.shrink();
                },
              );
            },
          ),

          const SizedBox(height: Spacing.lg),

          // Use different account button
          TextButton(
            onPressed: _isLoading ? null : _useDifferentAccount,
            child: Text(l10n.useDifferentAccount),
          ),

          const SizedBox(height: Spacing.xl),

          // Info box
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: Radii.mdRadius,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    l10n.pinLoginInfo,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
