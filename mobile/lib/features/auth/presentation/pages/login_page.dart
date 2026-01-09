import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/services/biometric_service.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../providers/auth_providers.dart';
import '../widgets/widgets.dart';

/// Page for existing user login with PIN
class LoginPage extends ConsumerStatefulWidget {
  /// Optional phone number passed from phone entry page (on 409 phone_registered)
  /// When provided, this phone is used instead of the stored phone number
  final String? phoneNumber;

  const LoginPage({super.key, this.phoneNumber});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _pinKey = GlobalKey<PinInputFieldState>();

  bool _isLoading = false;
  bool _isBiometricLoading = false;
  String? _errorText;
  String? _storedPhone;

  @override
  void initState() {
    super.initState();
    _loadStoredPhone();
    // Biometric login is only triggered when user taps the button
    // to avoid interrupting PIN entry with an unexpected popup
  }

  Future<void> _loadStoredPhone() async {
    // Use passed phone number if available, otherwise load from storage
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _storedPhone = widget.phoneNumber;
        });
      }
      return;
    }

    final phoneAsync = await ref.read(storedPhoneNumberProvider.future);
    if (mounted) {
      setState(() {
        _storedPhone = phoneAsync;
      });
    }
  }

  Future<void> _loginWithPin(String pin) async {
    if (_storedPhone == null) {
      setState(() {
        _errorText = 'No phone number stored. Please register first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.login(_storedPhone!, pin);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      // Check if we should offer biometric setup before navigating
      final isBiometricEnabled = await ref.read(
        isBiometricLoginEnabledProvider.future,
      );
      final biometricService = ref.read(biometricServiceProvider);
      final biometricAvailable = await biometricService.isBiometricAvailable();

      if (!isBiometricEnabled && biometricAvailable && mounted) {
        await _offerBiometricSetup(pin);
      }

      if (mounted) {
        context.go('/');
      }
    } else {
      setState(() {
        _errorText =
            result.errorOrNull?.displayMessage ?? S.of(context).errorInvalidPin;
      });
      _pinKey.currentState?.clear();
    }
  }

  Future<void> _onPinCompleted(String pin) async {
    await _loginWithPin(pin);
  }

  Future<void> _offerBiometricSetup(String pin) async {
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

    if (shouldEnable == true && mounted) {
      final biometricNotifier = ref.read(biometricLoginProvider.notifier);
      final result = await biometricNotifier.enableBiometric(pin);

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

  Future<void> _onUseBiometrics() async {
    if (_storedPhone == null) {
      setState(() {
        _errorText = 'No phone number stored. Please register first.';
      });
      return;
    }

    setState(() {
      _isBiometricLoading = true;
      _errorText = null;
    });

    final biometricNotifier = ref.read(biometricLoginProvider.notifier);
    final result = await biometricNotifier.authenticateAndGetPin();

    if (!mounted) return;

    if (result.isSuccess) {
      final pin = result.dataOrNull!;
      // Now login with the stored PIN
      await _loginWithPin(pin);
    } else {
      setState(() {
        _isBiometricLoading = false;
        // Don't show error for user cancelled
        if (result.errorOrNull?.displayMessage !=
            'Biometric authentication failed') {
          _errorText = result.errorOrNull?.displayMessage;
        }
      });
    }
  }

  void _onForgotPin() {
    // Navigate to phone entry to start fresh
    context.go('/auth/phone');
  }

  void _onDifferentAccount() {
    context.go('/auth/phone');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isBiometricEnabledAsync = ref.watch(isBiometricLoginEnabledProvider);
    final biometricAvailableAsync = ref.watch(isBiometricAvailableProvider);

    // Determine if biometric button should be shown
    final showBiometricButton = biometricAvailableAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, _) => false,
    );
    final biometricEnabled = isBiometricEnabledAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, _) => false,
    );

    return AuthPageLayout(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),
          if (_isLoading || _isBiometricLoading)
            Column(
              children: [
                const CircularProgressIndicator(),
                if (_isBiometricLoading) ...[
                  const SizedBox(height: Spacing.md),
                  const Text('Authenticating with biometrics...'),
                ],
              ],
            )
          else
            PinInputField(
              key: _pinKey,
              onCompleted: _onPinCompleted,
              autoFocus: true, // Always focus PIN input, biometric is manual
              errorText: _errorText,
            ),
          const SizedBox(height: Spacing.xl),
          // Biometric button - only show if biometrics are enabled (setup happens after PIN login)
          if (showBiometricButton &&
              biometricEnabled &&
              !_isLoading &&
              !_isBiometricLoading)
            OutlinedButton.icon(
              onPressed: _onUseBiometrics,
              icon: const Icon(Icons.fingerprint),
              label: Text(l10n.useBiometrics),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          const SizedBox(height: Spacing.lg),
          // Forgot PIN link
          TextButton(onPressed: _onForgotPin, child: Text(l10n.forgotPin)),
          const SizedBox(height: Spacing.sm),
          // Use different account link
          TextButton(
            onPressed: _onDifferentAccount,
            child: const Text('Use a different phone number'),
          ),
        ],
      ),
    );
  }
}
