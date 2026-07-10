import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/validators/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Requests a password-reset email for the given address.
///
/// Always shows a generic confirmation on success (never confirms/denies
/// whether the email exists) to avoid leaking account existence.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String? emailError = Validators.email(_emailController.text);
    setState(() => _emailError = emailError);
    if (emailError != null) return;

    final bool success = await ref.read(authControllerProvider.notifier).forgotPassword(
          email: _emailController.text.trim(),
        );

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (Object error, StackTrace stackTrace) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    final bool isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_emailSent) ...<Widget>[
              const Text(
                'If an account exists for that email, a reset link has been sent.',
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Back to Login',
                onPressed: () => context.go('/login'),
              ),
            ] else ...<Widget>[
              const Text('Enter your email and we will send you a reset link.'),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Send Reset Email',
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
