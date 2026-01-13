import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/services/biometric_service.dart';
import '../../../../shared/theme/typography.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/pin_input_field.dart';

/// Page for setting up PIN after email/password authentication
/// This is a simplified version without the registration data
class PinSetupEmailPage extends ConsumerStatefulWidget {
  const PinSetupEmailPage({super.key});

  @override
  ConsumerState<PinSetupEmailPage> createState() => _PinSetupEmailPageState();
}

class _PinSetupEmailPageState extends ConsumerState<PinSetupEmailPage> {
  final _pinKey = GlobalKey<PinInputFieldState>();
  final _confirmPinKey = GlobalKey<PinInputFieldState>();

  String? _firstPin;
  bool _isConfirming = false;
  String? _errorText;
  bool _isProcessing = false;

  void _onPinEntered(String pin) async {
    if (_isProcessing) return;

    if (!_isConfirming) {
      // First entry - store and ask for confirmation
      setState(() {
        _firstPin = pin;
        _isConfirming = true;
        _errorText = null;
      });
      return;
    }

    // Second entry - verify match
    if (pin != _firstPin) {
      setState(() {
        _firstPin = null;
        _isConfirming = false;
        _errorText = S.of(context).pinMismatch;
      });
      _confirmPinKey.currentState?.clear();
      return;
    }

    // PINs match - complete setup
    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    // Complete PIN setup
    await ref.read(authProvider.notifier).completePinSetup(pin);

    if (!mounted) return;

    // Offer biometric setup
    await _offerBiometricSetup(pin);

    // Navigation will be handled by router
  }

  Future<void> _offerBiometricSetup(String pin) async {
    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isBiometricAvailable();

    if (!isAvailable || !mounted) return;

    final biometricType = await biometricService.getBiometricDescription();

    if (!mounted) return;

    final l10n = S.of(context);

    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.enableBiometricTitle),
        content: Text(l10n.enableBiometricMessage(biometricType)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.enable),
          ),
        ],
      ),
    );

    if (shouldEnable == true && mounted) {
      // Enable biometric login with the PIN
      final biometricNotifier = ref.read(biometricLoginProvider.notifier);
      await biometricNotifier.enableBiometric(pin);
    }
  }

  void _startOver() {
    setState(() {
      _firstPin = null;
      _isConfirming = false;
      _errorText = null;
    });
    _pinKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: _isConfirming ? l10n.confirmPinTitle : l10n.setupPinTitle,
      subtitle: _isConfirming ? l10n.confirmPinSubtitle : l10n.setupPinSubtitle,
      showBackButton: false, // Can't go back from this screen
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: Spacing.xl),

          // PIN Input
          if (_isProcessing)
            const CircularProgressIndicator()
          else if (!_isConfirming)
            PinInputField(
              key: _pinKey,
              onCompleted: _onPinEntered,
              autoFocus: true,
            )
          else
            PinInputField(
              key: _confirmPinKey,
              onCompleted: _onPinEntered,
              autoFocus: true,
            ),

          // Error message
          if (_errorText != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              _errorText!,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],

          // Reset button (when confirming)
          if (_isConfirming && !_isProcessing) ...[
            const SizedBox(height: Spacing.lg),
            TextButton(onPressed: _startOver, child: Text(l10n.startOver)),
          ],

          const SizedBox(height: Spacing.xl),

          // PIN requirements hint
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
                    'Your PIN should be 4 digits and easy to remember but hard to guess.',
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
