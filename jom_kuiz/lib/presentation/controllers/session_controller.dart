import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_event_bus.dart';
import '../../domain/entities/session_status.dart';
import '../providers/admin_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/child_providers.dart';

/// Drives the app's top-level auth redirect decisions (splash screen,
/// [RouteGuard]).
///
/// Built manually (no `riverpod_generator`) so this compiles without a
/// `build_runner` codegen step.
final AsyncNotifierProvider<SessionController, SessionStatus>
    sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionStatus>(
        SessionController.new);

class SessionController extends AsyncNotifier<SessionStatus> {
  @override
  Future<SessionStatus> build() async {
    // Subscribe to auth events emitted by [AuthInterceptor] during the
    // lifetime of this provider. The interceptor lives in the network layer
    // and cannot access Riverpod, so it publishes to [AuthEventBus] instead.
    final StreamSubscription<AuthEvent> sub =
        AuthEventBus.instance.stream.listen(_onAuthEvent);
    ref.onDispose(sub.cancel);

    return ref.read(authServiceProvider).checkSession();
  }

  /// Reacts to auth state changes originating in the network layer.
  void _onAuthEvent(AuthEvent event) {
    switch (event) {
      case AuthEvent.tokenRefreshed:
        // Silent refresh succeeded — we are still authenticated.
        // The new tokens are already in secure storage; no state change needed.
        break;
      case AuthEvent.sessionExpired:
        // The refresh token is invalid (expired, revoked, or missing).
        // Force logout only when we are currently in an authenticated state to
        // avoid double-triggering logout if the event fires during startup.
        final AsyncData<SessionStatus>? data = state.asData;
        if (data?.value == SessionStatus.authenticated) {
          logout();
        }
        break;
    }
  }

  // ── Public operations ─────────────────────────────────────────────────────

  /// Re-runs the session check (e.g. after app resume).
  Future<void> refresh() async {
    state = const AsyncValue<SessionStatus>.loading();
    state = await AsyncValue.guard(
        () => ref.read(authServiceProvider).checkSession());
  }

  /// Called by [AuthController] immediately after a successful login so the
  /// router redirects without waiting for a full [refresh] round-trip.
  void markAuthenticated() {
    state = const AsyncValue<SessionStatus>.data(SessionStatus.authenticated);
  }

  Future<void> logout() async {
    state = const AsyncValue<SessionStatus>.loading();
    await ref.read(authServiceProvider).logout();
    // Clear role and selected child so the next login starts fresh.
    // Invalidate isAdminProvider so the cached admin-check result is discarded;
    // it will re-run (returning false) the next time any widget watches it.
    ref.read(userRoleProvider.notifier).state = '';
    ref.invalidate(isAdminProvider);
    ref.read(currentChildIdProvider.notifier).state = '';
    state =
        const AsyncValue<SessionStatus>.data(SessionStatus.unauthenticated);
  }
}
