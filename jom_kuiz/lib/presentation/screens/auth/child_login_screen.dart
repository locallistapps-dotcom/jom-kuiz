import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validators/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../providers/login_preferences_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Child login screen — requires Student ID + Username + Password.
///
/// Student ID and username are remembered via SharedPreferences and
/// pre-filled on the next visit. Password is never stored.
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
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Remember credentials ──────────────────────────────────────────────────

  Future<void> _loadRememberedCredentials() async {
    final creds = await ref
        .read(loginPreferencesServiceProvider)
        .getChildCredentials();
    if (creds != null && mounted) {
      _studentIdController.text = creds.studentId;
      _usernameController.text = creds.username;
    }
  }

  Future<void> _saveCredentials() async {
    await ref.read(loginPreferencesServiceProvider).saveChildCredentials(
          studentId: _studentIdController.text.trim(),
          username: _usernameController.text.trim().toLowerCase(),
        );
  }

  // ── Validation + submit ───────────────────────────────────────────────────

  bool _validate() {
    final String? studentIdError =
        Validators.studentId(_studentIdController.text);
    final String? usernameError = _usernameController.text.trim().isEmpty
        ? 'Username diperlukan'
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

    final bool success =
        await ref.read(authControllerProvider.notifier).loginAsChild(
              studentId: _studentIdController.text.trim(),
              username: _usernameController.text.trim().toLowerCase(),
              password: _passwordController.text,
            );

    if (success) {
      // Remember the non-sensitive credentials for next time.
      await _saveCredentials();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider,
        (_, AsyncValue<void> next) {
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
      appBar: AppBar(title: const Text('Log Masuk Pelajar')),
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
              'Log Masuk Pelajar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Masukkan Student ID, username dan kata laluan anda',
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
              hintText: 'cth. 48392715',
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
              label: 'Kata Laluan',
              controller: _passwordController,
              enabled: !isLoading,
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Log Masuk',
              isLoading: isLoading,
              onPressed: isLoading ? null : _submit,
            ),
            const SizedBox(height: 16),
            const _DisabledAccountNote(),
          ],
        ),
      ),
    );
  }
}

// ── _DisabledAccountNote ─────────────────────────────────────────────────────

class _DisabledAccountNote extends StatelessWidget {
  const _DisabledAccountNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jika akaun anda diblokkan, sila hubungi ibu bapa anda.',
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
