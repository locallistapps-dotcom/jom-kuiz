import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/session_status.dart';
import '../providers/auth_providers.dart';
import '../providers/child_providers.dart';

/// Drives the app's top-level auth redirect decisions (splash screen,
/// [RouteGuard]).
///
/// Built manually (no `riverpod_generator`) so this compiles without a
/// `build_runner` codegen step.
final AsyncNotifierProvider<SessionController, SessionStatus> sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionStatus>(SessionController.new);

class SessionController extends AsyncNotifier<SessionStatus> {
  @override
  Future<SessionStatus> build() {
    return ref.watch(authServiceProvider).checkSession();
  }

  /// Re-runs the session check (e.g. after app resume).
  Future<void> refresh() async {
    state = const AsyncValue<SessionStatus>.loading();
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).checkSession());
  }

  /// Called by [AuthController] immediately after a successful login so the
  /// router redirects without waiting for a full [refresh] round-trip.
  void markAuthenticated() {
    state = const AsyncValue<SessionStatus>.data(SessionStatus.authenticated);
  }

  Future<void> logout() async {
    state = const AsyncValue<SessionStatus>.loading();
    await ref.read(authServiceProvider).logout();
    // Clear role, admin flag, and selected child so the next login starts fresh.
    ref.read(userRoleProvider.notifier).state = '';
    ref.read(isAdminProvider.notifier).state = false;
    ref.read(currentChildIdProvider.notifier).state = '';
    state = const AsyncValue<SessionStatus>.data(SessionStatus.unauthenticated);
  }
}
