import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/validators/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Parent registration screen: full name, email, password (min 8 chars),
/// confirm password, and a required "agree to terms" checkbox.
///
/// Email uniqueness is enforced server-side (`AUTH-002`); this screen only
/// surfaces the resulting error, it does not check uniqueness itself.
class RegisterParentScreen extends ConsumerStatefulWidget {
  const RegisterParentScreen({super.key});

  @override
  ConsumerState<RegisterParentScreen> createState() => _RegisterParentScreenState();
}

class _RegisterParentScreenState extends ConsumerState<RegisterParentScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _agreeTerms = false;

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String? fullNameError = Validators.required(_fullNameController.text, fieldName: 'Full name');
    final String? emailError = Validators.email(_emailController.text);
    final String? passwordError = Validators.password(_passwordController.text);
    final String? confirmPasswordError = Validators.confirmPassword(
      _confirmPasswordController.text,
      _passwordController.text,
    );
    final String? termsError = Validators.requireTrue(
      _agreeTerms,
      message: 'You must agree to the Terms to continue',
    );

    setState(() {
      _fullNameError = fullNameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
      _termsError = termsError;
    });

    if ([fullNameError, emailError, passwordError, confirmPasswordError, termsError]
        .any((e) => e != null)) {
      return;
    }

    final bool success = await ref.read(authControllerProvider.notifier).register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please log in.')),
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
      appBar: AppBar(title: const Text('Register Parent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              label: 'Full Name',
              controller: _fullNameController,
              enabled: !isLoading,
              errorText: _fullNameError,
              onChanged: (_) {
                if (_fullNameError != null) setState(() => _fullNameError = null);
              },
            ),
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
            const SizedBox(height: 16),
            PasswordField(
              label: 'Password',
              controller: _passwordController,
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              errorText: _confirmPasswordError,
              onChanged: (_) {
                if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
              },
            ),
            CheckboxListTile(
              value: _agreeTerms,
              onChanged: isLoading ? null : (value) => setState(() => _agreeTerms = value ?? false),
              title: const Text('I agree to the Terms & Conditions'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_termsError != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  _termsError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Create Account',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : () => context.go('/login'),
              child: const Text('Already have an account? Log In'),
            ),
          ],
        ),
      ),
    );
  }
}
