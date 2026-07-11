import 'package:flutter/material.dart';

/// Password input with a built-in visibility toggle.
///
/// Wraps [TextFormField] so it integrates with [Form] / [validator] support.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.label,
    super.key,
    this.controller,
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.autofillHints,
    this.enabled = true,
    this.validator,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      focusNode: widget.focusNode,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
