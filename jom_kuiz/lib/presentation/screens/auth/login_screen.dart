import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Placeholder login screen.
///
/// UI shell only -- form submission is intentionally not wired to
/// [AuthService] yet. That lands with the auth feature module.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppTextField(
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const PasswordField(label: 'Password'),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Log In', onPressed: () {}),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
