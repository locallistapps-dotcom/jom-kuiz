import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/validators/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/password_field.dart';

/// Sets a new password using the reset token from the emailed link
/// (`/reset-password?token=...`, read via [resetToken]).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.resetToken});

  final String? resetToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String? resetToken = widget.resetToken;
    if (resetToken == null || resetToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This reset link is invalid or has expired.')),
      );
      return;
    }

    final String? newPasswordError = Validators.password(_newPasswordController.text);
    final String? confirmPasswordError = Validators.confirmPassword(
      _confirmPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _newPasswordError = newPasswordError;
      _confirmPasswordError = confirmPasswordError;
    });

    if (newPasswordError != null || confirmPasswordError != null) return;

    final bool success = await ref.read(authControllerProvider.notifier).resetPassword(
          resetToken: resetToken,
          newPassword: _newPasswordController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset. Please log in.')),
      );
      context.go('/login');
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
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PasswordField(
              label: 'New Password',
              controller: _newPasswordController,
              enabled: !isLoading,
              errorText: _newPasswordError,
              onChanged: (_) {
                if (_newPasswordError != null) setState(() => _newPasswordError = null);
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              enabled: !isLoading,
              errorText: _confirmPasswordError,
              onChanged: (_) {
                if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Reset Password',
              isLoading: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
