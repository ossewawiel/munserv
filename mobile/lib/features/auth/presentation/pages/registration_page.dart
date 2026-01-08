import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../shared/theme/typography.dart';
import '../widgets/widgets.dart';

/// Page for new user registration (profile setup)
class RegistrationPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String tempToken;

  const RegistrationPage({
    super.key,
    required this.phoneNumber,
    required this.tempToken,
  });

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _addressController = TextEditingController();

  final bool _isLoading = false;
  String? _errorText;
  GeoPoint? _location;
  bool _isLocating = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _surnameController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _location != null;
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
    });

    // TODO: Implement actual location detection using geolocator package
    // For now, using mock location
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLocating = false;
      // Mock location - Johannesburg
      _location = const GeoPoint(latitude: -26.2041, longitude: 28.0473);
      _addressController.text = '123 Main Street, Johannesburg';
    });
  }

  Future<void> _onContinue() async {
    final formState = _formKey.currentState;
    final location = _location;
    if (formState == null || !formState.validate() || location == null) {
      return;
    }

    // Navigate to PIN setup with all the registration data
    context.pushNamed(
      'pinSetup',
      queryParameters: {
        'phone': widget.phoneNumber,
        'tempToken': widget.tempToken,
        'firstName': _firstNameController.text,
        'surname': _surnameController.text,
        'address': _addressController.text,
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: l10n.profileTitle,
      subtitle: l10n.profileSubtitle,
      showBackButton: true,
      bottomAction: LoadingButton(
        label: l10n.continueButton,
        onPressed: _onContinue,
        isLoading: _isLoading,
        enabled: _isFormValid,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Spacing.md),
            // First name
            TextFormField(
              controller: _firstNameController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.firstNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.md),
            // Surname
            TextFormField(
              controller: _surnameController,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.surnameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your surname';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacing.lg),
            // Location detection button
            LoadingOutlinedButton(
              label: l10n.detectLocation,
              onPressed: _detectLocation,
              isLoading: _isLocating,
            ),
            const SizedBox(height: Spacing.md),
            // Address
            TextFormField(
              controller: _addressController,
              enabled: !_isLoading && !_isLocating,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.addressLabel,
                hintText: l10n.addressHint,
                prefixIcon: const Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            if (_location case final loc?) ...[
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      'Location detected: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_errorText case final error?) ...[
              const SizedBox(height: Spacing.md),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
