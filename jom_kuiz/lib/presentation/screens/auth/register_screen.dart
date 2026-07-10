import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Placeholder registration screen. UI shell only -- see [LoginScreen].
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppTextField(label: 'Full Name'),
            const SizedBox(height: 16),
            const AppTextField(
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const PasswordField(label: 'Password'),
            const SizedBox(height: 16),
            const PasswordField(label: 'Confirm Password'),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create Account', onPressed: () {}),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Log In'),
            ),
          ],
        ),
      ),
    );
  }
}
