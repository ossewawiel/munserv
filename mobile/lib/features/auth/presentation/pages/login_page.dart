import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../providers/auth_providers.dart';
import '../widgets/widgets.dart';

/// Page for existing user login with PIN
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _pinKey = GlobalKey<PinInputFieldState>();

  bool _isLoading = false;
  String? _errorText;
  String? _storedPhone;

  @override
  void initState() {
    super.initState();
    _loadStoredPhone();
  }

  Future<void> _loadStoredPhone() async {
    final phoneAsync = await ref.read(storedPhoneNumberProvider.future);
    if (mounted) {
      setState(() {
        _storedPhone = phoneAsync;
      });
    }
  }

  Future<void> _onPinCompleted(String pin) async {
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
      context.go('/');
    } else {
      setState(() {
        _errorText = result.errorOrNull?.displayMessage ??
            S.of(context).errorInvalidPin;
      });
      _pinKey.currentState?.clear();
    }
  }

  Future<void> _onUseBiometrics() async {
    // TODO: Implement biometric authentication
    // For MVP, this is a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric authentication coming soon')),
    );
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

    return AuthPageLayout(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            PinInputField(
              key: _pinKey,
              onCompleted: _onPinCompleted,
              autoFocus: true,
              errorText: _errorText,
            ),
          const SizedBox(height: Spacing.xl),
          // Biometric button
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
          TextButton(
            onPressed: _onForgotPin,
            child: Text(l10n.forgotPin),
          ),
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
