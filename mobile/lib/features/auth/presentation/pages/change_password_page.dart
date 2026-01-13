import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/loading_button.dart';
import '../widgets/password_input_field.dart';

/// Page for first-time password change after approval
/// Shown when mustChangePassword is true from login response
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    final l10n = S.of(context);

    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordTooShort;
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return l10n.passwordNeedsUppercase;
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return l10n.passwordNeedsLowercase;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return l10n.passwordNeedsNumber;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = S.of(context);

    if (value != _newPasswordController.text) {
      return l10n.passwordsMustMatch;
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.fold(
      onSuccess: (_) {
        // Navigation handled by router based on auth state
      },
      onFailure: (error) {
        setState(() {
          _errorText = error.displayMessage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AuthPageLayout(
      title: l10n.changePasswordTitle,
      subtitle: l10n.changePasswordSubtitle,
      showBackButton: false, // Can't go back from this screen
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current password (the temp password from email)
            PasswordInputField(
              controller: _currentPasswordController,
              enabled: !_isLoading,
              labelText: l10n.currentPasswordLabel,
              helperText: l10n.tempPasswordHelp,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => _newPasswordFocusNode.requestFocus(),
            ),
            const SizedBox(height: Spacing.lg),

            // New password with requirements
            PasswordInputField(
              controller: _newPasswordController,
              enabled: !_isLoading,
              labelText: l10n.newPasswordLabel,
              validator: _validateNewPassword,
              focusNode: _newPasswordFocusNode,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => _confirmPasswordFocusNode.requestFocus(),
            ),
            const SizedBox(height: Spacing.xs),

            // Password requirements info
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              child: Text(
                l10n.passwordRequirements,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Confirm password
            PasswordInputField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              labelText: l10n.confirmPasswordLabel,
              validator: _validateConfirmPassword,
              focusNode: _confirmPasswordFocusNode,
              onEditingComplete: _changePassword,
            ),

            // Error message
            if (_errorText != null) ...[
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: Radii.mdRadius,
                ),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: Spacing.xl),

            // Submit button
            LoadingButton(
              label: l10n.changePasswordButton,
              onPressed: _changePassword,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
