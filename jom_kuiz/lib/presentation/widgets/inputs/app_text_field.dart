import 'package:flutter/material.dart';

/// Standard single-line text input used across forms.
///
/// Wraps [TextFormField] so it works inside a [Form] with [validator],
/// and also supports manual [errorText] display for ad-hoc validation.
///
/// For password inputs use [PasswordField] so obscure/visibility toggling
/// stays consistent app-wide.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.enabled = true,
    this.autofillHints,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.initialValue,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      enabled: enabled,
      autofillHints: autofillHints,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onTap: onTap,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
      ),
    );
  }
}
