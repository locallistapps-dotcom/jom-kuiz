import 'package:flutter/material.dart';

import '../buttons/primary_button.dart';

/// Standard full-area error state with an optional retry action.
///
/// Named `AppErrorWidget` (not `ErrorWidget`) to avoid clashing with
/// Flutter's built-in `ErrorWidget`.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 24),
              PrimaryButton(label: 'Retry', onPressed: onRetry, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}
