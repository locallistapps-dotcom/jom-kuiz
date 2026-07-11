import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validators/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Child login screen — requires Student ID + Username + Password.
///
/// A disabled child account receives an explicit error rather than a generic
/// "invalid credentials" message, so parents can identify the problem quickly.
class ChildLoginScreen extends ConsumerStatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  ConsumerState<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends ConsumerState<ChildLoginScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _studentIdError;
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _studentIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final String? studentIdError =
        Validators.studentId(_studentIdController.text);
    final String? usernameError = _usernameController.text.trim().isEmpty
        ? 'Username is required'
        : null;
    final String? passwordError = Validators.password(_passwordController.text);

    setState(() {
      _studentIdError = studentIdError;
      _usernameError = usernameError;
      _passwordError = passwordError;
    });

    return studentIdError == null &&
        usernameError == null &&
        passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    await ref.read(authControllerProvider.notifier).loginAsChild(
          studentId: _studentIdController.text.trim(),
          username: _usernameController.text.trim().toLowerCase(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, AsyncValue<void> next) {
      next.whenOrNull(
        error: (Object error, _) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    final bool isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Header ──────────────────────────────────────────────────────
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Student Login',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Enter your Student ID, username and password',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),

            // ── Fields ───────────────────────────────────────────────────────
            AppTextField(
              label: 'Student ID',
              controller: _studentIdController,
              keyboardType: TextInputType.number,
              hintText: 'e.g. 48392715',
              errorText: _studentIdError,
              enabled: !isLoading,
              onChanged: (_) {
                if (_studentIdError != null) {
                  setState(() => _studentIdError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Username',
              controller: _usernameController,
              keyboardType: TextInputType.text,
              errorText: _usernameError,
              enabled: !isLoading,
              onChanged: (_) {
                if (_usernameError != null) {
                  setState(() => _usernameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Password',
              controller: _passwordController,
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Login',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            const _DisabledAccountNote(),
          ],
        ),
      ),
    );
  }
}

class _DisabledAccountNote extends StatelessWidget {
  const _DisabledAccountNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'If your account is disabled, please contact your parent.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
