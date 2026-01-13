import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Password input field with visibility toggle
/// Follows Material Design 3 specifications with filled style
class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? labelText;
  final String? helperText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;

  const PasswordInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.labelText,
    this.helperText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.onEditingComplete,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      autofillHints: const [AutofillHints.password],
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
        labelText: widget.labelText ?? l10n.passwordLabel,
        helperText: widget.helperText,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      validator:
          widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return l10n.passwordRequired;
            }
            return null;
          },
    );
  }
}
