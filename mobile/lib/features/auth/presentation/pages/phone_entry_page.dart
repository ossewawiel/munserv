import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../providers/auth_providers.dart';
import '../widgets/widgets.dart';

/// Page for entering phone number to start authentication flow
class PhoneEntryPage extends ConsumerStatefulWidget {
  const PhoneEntryPage({super.key});

  @override
  ConsumerState<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends ConsumerState<PhoneEntryPage> {
  final _phoneController = TextEditingController();
  String _phoneNumber = '';
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    // SA phone numbers: 9 digits after country code
    final digits = _phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    // +27 + 9 digits = 12 total, or just 9-10 digits
    return digits.length >= 11 && digits.length <= 12;
  }

  Future<void> _onContinue() async {
    if (!_isPhoneValid) {
      setState(() {
        _errorText = S.of(context).errorInvalidPhone;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.requestOtp(_phoneNumber);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      // Navigate to OTP verification page
      context.pushNamed('otp', queryParameters: {'phone': _phoneNumber});
    } else {
      final error = result.errorOrNull;

      // Handle 409 phone_registered: redirect to login with this phone
      if (error != null && error.isPhoneRegistered) {
        context.goNamed('login', queryParameters: {'phone': _phoneNumber});
        return;
      }

      setState(() {
        _errorText = error?.displayMessage ?? S.of(context).errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return AuthPageLayout(
      title: l10n.phoneEntryTitle,
      subtitle: l10n.phoneEntrySubtitle,
      bottomAction: LoadingButton(
        label: l10n.continueButton,
        onPressed: _onContinue,
        isLoading: _isLoading,
        enabled: _isPhoneValid,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.xl),
          PhoneInputField(
            controller: _phoneController,
            errorText: _errorText,
            enabled: !_isLoading,
            autoFocus: true,
            onChanged: (value) {
              setState(() {
                _phoneNumber = value;
                _errorText = null;
              });
            },
            onSubmitted: _onContinue,
          ),
        ],
      ),
    );
  }
}
