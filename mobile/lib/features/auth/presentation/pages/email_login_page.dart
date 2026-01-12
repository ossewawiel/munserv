import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/typography.dart';
import '../../../../shared/utils/result.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../../providers/auth_providers.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/email_input_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/password_input_field.dart';

/// Login page with email and password
/// Used for members who registered via web portal
class EmailLoginPage extends ConsumerStatefulWidget {
  const EmailLoginPage({super.key});

  @override
  ConsumerState<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends ConsumerState<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final email = await ref.read(storedEmailProvider.future);
    if (email != null && mounted) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
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
      title: l10n.loginTitle,
      subtitle: l10n.loginWithEmailSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            EmailInputField(
              controller: _emailController,
              enabled: !_isLoading,
              onEditingComplete: () => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: Spacing.md),

            // Password field
            PasswordInputField(
              controller: _passwordController,
              enabled: !_isLoading,
              labelText: l10n.passwordLabel,
              focusNode: _passwordFocusNode,
              onEditingComplete: _login,
            ),

            // Error message
            if (_errorText != null) ...[
              const SizedBox(height: Spacing.md),
              FormErrorBanner(
                message: _errorText!,
                onDismiss: () => setState(() => _errorText = null),
              ),
            ],

            const SizedBox(height: Spacing.xl),

            // Login button
            LoadingButton(
              label: l10n.loginButton,
              onPressed: _login,
              isLoading: _isLoading,
            ),

            const SizedBox(height: Spacing.lg),

            // Info about web registration
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: Radii.mdRadius,
              ),
              child: Column(
                children: [
                  Text(
                    l10n.noAccountQuestion,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.registerOnWebInstruction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
