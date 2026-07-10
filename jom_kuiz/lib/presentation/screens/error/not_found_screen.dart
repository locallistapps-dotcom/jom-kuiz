import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/buttons/primary_button.dart';

/// Standard 404 / unmatched-route screen.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('404', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Go Home',
                expand: false,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
