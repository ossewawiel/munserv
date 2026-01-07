import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../providers/auth_providers.dart';
import '../widgets/widgets.dart';

/// Page for creating a new PIN during registration
class PinSetupPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String tempToken;
  final String firstName;
  final String surname;
  final String address;
  final double latitude;
  final double longitude;
  final String sectorId;

  const PinSetupPage({
    super.key,
    required this.phoneNumber,
    required this.tempToken,
    required this.firstName,
    required this.surname,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.sectorId,
  });

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final _pinKey = GlobalKey<PinInputFieldState>();
  final _confirmPinKey = GlobalKey<PinInputFieldState>();

  String _pin = '';
  bool _isLoading = false;
  String? _errorText;
  bool _showConfirm = false;

  void _onPinCompleted(String pin) {
    setState(() {
      _pin = pin;
      _showConfirm = true;
      _errorText = null;
    });
  }

  void _onConfirmPinCompleted(String confirmPin) {
    if (_pin != confirmPin) {
      setState(() {
        _errorText = S.of(context).pinMismatch;
      });
      _confirmPinKey.currentState?.clear();
    } else {
      _completeRegistration();
    }
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.completeRegistration(
      phoneNumber: widget.phoneNumber,
      tempToken: widget.tempToken,
      firstName: widget.firstName,
      surname: widget.surname,
      pin: _pin,
      location: GeoPoint(
        latitude: widget.latitude,
        longitude: widget.longitude,
      ),
      address: widget.address,
      sectorId: widget.sectorId,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      // Show success message and navigate to home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).successRegistration)),
      );
      context.go('/');
    } else {
      setState(() {
        _errorText = result.errorOrNull?.displayMessage ??
            S.of(context).errorGeneric;
        // Reset PINs on error
        _pin = '';
        _showConfirm = false;
      });
      _pinKey.currentState?.clear();
    }
  }

  void _onBack() {
    if (_showConfirm) {
      setState(() {
        _showConfirm = false;
        _errorText = null;
      });
      _pinKey.currentState?.clear();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: l10n.pinSetupTitle,
      subtitle: _showConfirm ? l10n.pinConfirmLabel : l10n.pinSetupSubtitle,
      showBackButton: true,
      onBack: _onBack,
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (!_showConfirm)
            PinInputField(
              key: _pinKey,
              onCompleted: _onPinCompleted,
              autoFocus: true,
              errorText: _errorText,
            )
          else
            PinInputField(
              key: _confirmPinKey,
              onCompleted: _onConfirmPinCompleted,
              autoFocus: true,
              errorText: _errorText,
            ),
          if (_errorText != null && !_isLoading) ...[
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
