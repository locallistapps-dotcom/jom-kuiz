import 'package:flutter/material.dart';

/// Standard secondary action button -- for actions that support the primary
/// flow without competing with it visually (e.g. "Cancel", "Skip").
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget button = OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
