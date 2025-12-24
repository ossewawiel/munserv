import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/typography.dart';

/// Phone number input with country code prefix
class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? errorText;
  final bool enabled;
  final bool autoFocus;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final String countryCode;

  const PhoneInputField({
    super.key,
    this.controller,
    this.errorText,
    this.enabled = true,
    this.autoFocus = false,
    this.onChanged,
    this.onSubmitted,
    this.countryCode = '+27',
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  String get fullPhoneNumber {
    final number = _controller.text.replaceAll(RegExp(r'\s+'), '');
    if (number.isEmpty) return '';
    // Remove leading 0 if present and add country code
    final cleanNumber = number.startsWith('0') ? number.substring(1) : number;
    return '${widget.countryCode}$cleanNumber';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: Radii.lgRadius,
            border: widget.errorText != null
                ? Border.all(color: theme.colorScheme.error, width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Country code prefix
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Text(
                  widget.countryCode,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              // Phone number input
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: '82 123 4567',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm + 4,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _PhoneNumberFormatter(),
                  ],
                  onChanged: (value) {
                    widget.onChanged?.call(fullPhoneNumber);
                  },
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: Spacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: Spacing.md),
            child: Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Formats phone number with spaces for readability
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Remove all spaces
    final digits = text.replaceAll(' ', '');

    // Format with spaces: XX XXX XXXX
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
