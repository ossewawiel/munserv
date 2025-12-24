import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/typography.dart';

/// A PIN input field with masked/hidden digits
class PinInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autoFocus;
  final bool obscureText;
  final String? errorText;

  const PinInputField({
    super.key,
    this.length = 4,
    this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.autoFocus = false,
    this.obscureText = true,
    this.errorText,
  });

  @override
  State<PinInputField> createState() => PinInputFieldState();
}

class PinInputFieldState extends State<PinInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
    setState(() {});
  }

  void _onChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLength = _controller.text.length;
    final hasError = widget.errorText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (index) {
              final isFilled = index < currentLength;
              final isCurrent = index == currentLength;

              return Container(
                width: 48,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: Radii.mdRadius,
                  border: Border.all(
                    color: hasError
                        ? theme.colorScheme.error
                        : isCurrent && _focusNode.hasFocus
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isFilled
                      ? widget.obscureText
                          ? Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface,
                                shape: BoxShape.circle,
                              ),
                            )
                          : Text(
                              _controller.text[index],
                              style: theme.textTheme.headlineSmall,
                            )
                      : null,
                ),
              );
            }),
          ),
        ),
        // Hidden text field for keyboard input
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: _onChanged,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
