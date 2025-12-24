import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../domain/otp_verify_result.dart';
import '../../providers/auth_providers.dart';
import '../widgets/widgets.dart';

/// Page for OTP code verification
class OtpVerifyPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerifyPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  bool _isLoading = false;
  String? _errorText;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _onOtpCompleted(String otp) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.verifyOtp(widget.phoneNumber, otp);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      final verifyResult = result.dataOrNull!;

      switch (verifyResult) {
        case OtpVerifyResultExistingUser():
          // Existing user - already authenticated by provider
          // Navigate to home
          context.go('/');
        case OtpVerifyResultNewUser(tempToken: final tempToken):
          // New user - navigate to registration
          context.pushNamed(
            'registration',
            queryParameters: {
              'phone': widget.phoneNumber,
              'tempToken': tempToken,
            },
          );
      }
    } else {
      setState(() {
        _errorText = result.errorOrNull?.displayMessage ??
            S.of(context).errorInvalidOtp;
      });
    }
  }

  Future<void> _onResendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.requestOtp(widget.phoneNumber);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent')),
      );
    } else {
      setState(() {
        _errorText = result.errorOrNull?.displayMessage ??
            S.of(context).errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: l10n.otpTitle,
      subtitle: l10n.otpSubtitle(widget.phoneNumber),
      showBackButton: true,
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),
          OtpInputField(
            onCompleted: _onOtpCompleted,
            enabled: !_isLoading,
            autoFocus: true,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Spacing.xl),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            TextButton(
              onPressed: _resendCountdown > 0 ? null : _onResendOtp,
              child: Text(
                _resendCountdown > 0
                    ? l10n.resendOtpIn(_resendCountdown)
                    : l10n.resendOtp,
              ),
            ),
        ],
      ),
    );
  }
}
