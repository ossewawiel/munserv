import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Email input field with validation
/// Follows Material Design 3 specifications with filled style
class EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;

  const EmailInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: l10n.emailLabel,
        prefixIcon: const Icon(Icons.email_outlined),
        hintText: 'example@email.com',
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return l10n.emailRequired;
            }
            if (!EmailValidator.validate(value)) {
              return l10n.invalidEmail;
            }
            return null;
          },
    );
  }
}
