import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/validators/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../providers/login_preferences_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Parent / Admin login screen.
///
/// Supports:
/// - Email + password login with inline validation.
/// - "Continue with Google" via Supabase OAuth (web only).
/// - Remembered email address (pre-filled from SharedPreferences).
/// - Loading state that disables all inputs and buttons to prevent
///   duplicate submissions.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Remember email ────────────────────────────────────────────────────────

  Future<void> _loadRememberedEmail() async {
    final String? savedEmail = await ref
        .read(loginPreferencesServiceProvider)
        .getParentEmail();
    if (savedEmail != null && mounted) {
      _emailController.text = savedEmail;
    }
  }

  Future<void> _saveEmail(String email) async {
    await ref
        .read(loginPreferencesServiceProvider)
        .saveParentEmail(email);
  }

  // ── Email + password login ────────────────────────────────────────────────

  Future<void> _submit() async {
    final String? emailError = Validators.email(_emailController.text);
    final String? passwordError = Validators.password(_passwordController.text);

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    if (emailError != null || passwordError != null) return;

    final bool success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (success) {
      await _saveEmail(_emailController.text.trim());
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  /// Initiates Supabase Google OAuth.
  ///
  /// On Flutter Web the browser navigates to the Google consent screen in the
  /// same tab. After authorisation Supabase redirects back to the app's root
  /// URL with the token pair in the URL fragment, which [AuthService] picks up
  /// automatically in [checkSession].
  ///
  /// This requires Google to be enabled as an OAuth provider in the Supabase
  /// dashboard, and the app's origin URL to be in the "Redirect URLs" allow-
  /// list under Authentication → URL Configuration.
  Future<void> _signInWithGoogle() async {
    if (!kIsWeb) {
      // OAuth redirect flow is only supported on Flutter Web in this build.
      // Mobile would need deep-link / custom-scheme configuration.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Log masuk Google hanya tersedia pada versi web.',
            ),
          ),
        );
      return;
    }

    setState(() => _isGoogleLoading = true);
    try {
      // Build the GoTrue OAuth URL. redirect_to must match an allow-listed URL
      // in the Supabase dashboard (Authentication → URL Configuration).
      final String redirectTo = Uri.base.origin;
      final Uri authUri =
          Uri.parse(AppConfig.supabaseUrl).replace(
        path: '/auth/v1/authorize',
        queryParameters: <String, String>{
          'provider': 'google',
          'redirect_to': redirectTo,
        },
      );

      // Navigate the current tab — Flutter Web re-initialises after redirect
      // and AuthService.checkSession() picks up the token from the URL fragment.
      final bool launched = await launchUrl(
        authUri,
        webOnlyWindowName: '_self',
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka halaman log masuk Google.'),
            ),
          );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Log masuk Google gagal. Sila cuba lagi.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
    final bool anyLoading = isLoading || _isGoogleLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Masuk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Email + password ──────────────────────────────────────────────
            AppTextField(
              label: 'E-mel',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              enabled: !anyLoading,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Kata Laluan',
              controller: _passwordController,
              autofillHints: const <String>[AutofillHints.password],
              enabled: !anyLoading,
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            CheckboxListTile(
              value: _rememberMe,
              onChanged: anyLoading
                  ? null
                  : (bool? value) =>
                      setState(() => _rememberMe = value ?? true),
              title: const Text('Ingat saya'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Log Masuk',
              isLoading: isLoading,
              onPressed: anyLoading ? null : _submit,
            ),

            // ── Divider ────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: <Widget>[
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // ── Google Sign-In ─────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: anyLoading ? null : _signInWithGoogle,
              icon: _isGoogleLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata_rounded, size: 22),
              label: const Text('Teruskan dengan Google'),
            ),

            // ── Footer links ───────────────────────────────────────────────
            const SizedBox(height: 12),
            TextButton(
              onPressed: anyLoading ? null : () => context.push('/forgot-password'),
              child: const Text('Lupa Kata Laluan?'),
            ),
            TextButton(
              onPressed: anyLoading ? null : () => context.push('/register'),
              child: const Text('Belum ada akaun? Daftar'),
            ),
            const Divider(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.school_outlined, size: 18),
              label: const Text('Log Masuk sebagai Pelajar'),
              onPressed: anyLoading ? null : () => context.push('/child-login'),
            ),
          ],
        ),
      ),
    );
  }
}
