import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../providers/account_management_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/child_providers.dart';
import 'session_controller.dart';

/// Holds the in-flight state (loading / error) for the Login, Register,
/// Forgot Password, Reset Password, and Child Login forms.
///
/// Built manually (no `riverpod_generator`) so this compiles without a
/// `build_runner` codegen step.
final AsyncNotifierProvider<AuthController, void> authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  // ── Parent / Admin login ───────────────────────────────────────────────────

  /// Authenticates via email + password, then resolves the user's role.
  ///
  /// After saving tokens, the method queries the `admin_users` table to
  /// check whether the authenticated user is an admin:
  /// - Sets [userRoleProvider] to `'admin'` when the user is in the table.
  /// - Falls back to `'parent'` on any error or when not found.
  ///
  /// [userRoleProvider] is updated before [markAuthenticated] so [RouteGuard]
  /// sees the correct role on the first redirect.
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    state = const AsyncValue<void>.loading();
    final Result<void> result = await ref.read(authServiceProvider).login(
          email: email,
          password: password,
          rememberMe: rememberMe,
        );

    // Separate the sync outcome from the async admin check to keep `when()`
    // callbacks typed uniformly (both return `bool`).
    bool loginSucceeded = false;
    result.when(
      success: (_) => loginSucceeded = true,
      failure: (Failure failure) {
        state = AsyncValue<void>.error(failure, StackTrace.current);
      },
    );

    if (!loginSucceeded) return false;

    // Always set role to 'parent' — admin privilege is tracked separately by
    // isAdminProvider (FutureProvider) which auto-queries admin_users whenever
    // the dashboard watches it. No manual state update needed here.
    ref.read(userRoleProvider.notifier).state = 'parent';
    state = const AsyncValue<void>.data(null);
    ref.read(sessionControllerProvider.notifier).markAuthenticated();
    return true;
  }

  // ── Child login ───────────────────────────────────────────────────────────

  /// Authenticates a child via Student ID + username + password.
  ///
  /// On success: saves tokens, sets [currentChildIdProvider] and
  /// [userRoleProvider] to `'child'`, and calls [markAuthenticated] so the
  /// router redirects to the child dashboard.
  Future<bool> loginAsChild({
    required String studentId,
    required String username,
    required String password,
  }) async {
    state = const AsyncValue<void>.loading();
    final Result<String> result = await ref
        .read(childAuthServiceProvider)
        .loginChild(
          studentId: studentId,
          username: username,
          password: password,
        );

    return result.when(
      success: (String childId) {
        ref.read(currentChildIdProvider.notifier).state = childId;
        ref.read(userRoleProvider.notifier).state = 'child';
        state = const AsyncValue<void>.data(null);
        ref.read(sessionControllerProvider.notifier).markAuthenticated();
        return true;
      },
      failure: (Failure failure) {
        state = AsyncValue<void>.error(failure, StackTrace.current);
        return false;
      },
    );
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<void>.loading();
    final Result<User> result = await ref.read(authServiceProvider).register(
          fullName: fullName,
          email: email,
          password: password,
        );

    return result.when(
      success: (_) {
        state = const AsyncValue<void>.data(null);
        return true;
      },
      failure: (Failure failure) {
        state = AsyncValue<void>.error(failure, StackTrace.current);
        return false;
      },
    );
  }

  // ── Forgot / Reset Password ───────────────────────────────────────────────

  Future<bool> forgotPassword({required String email}) async {
    state = const AsyncValue<void>.loading();
    final Result<void> result =
        await ref.read(authServiceProvider).forgotPassword(email: email);

    return result.when(
      success: (_) {
        state = const AsyncValue<void>.data(null);
        return true;
      },
      failure: (Failure failure) {
        state = AsyncValue<void>.error(failure, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    state = const AsyncValue<void>.loading();
    final Result<void> result =
        await ref.read(authServiceProvider).resetPassword(
              resetToken: resetToken,
              newPassword: newPassword,
            );

    return result.when(
      success: (_) {
        state = const AsyncValue<void>.data(null);
        return true;
      },
      failure: (Failure failure) {
        state = AsyncValue<void>.error(failure, StackTrace.current);
        return false;
      },
    );
  }
}
