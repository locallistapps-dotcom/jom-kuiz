import 'dart:async';

/// Authentication events emitted by the network layer when session state
/// changes outside normal user interaction (e.g. an automatic token refresh
/// triggered by a 401, or a failed refresh that forces logout).
enum AuthEvent {
  /// The access token was successfully renewed via a silent refresh.
  ///
  /// The new token pair is already persisted to secure storage; no further
  /// action is required by the UI.
  tokenRefreshed,

  /// The refresh token is no longer valid — the user must re-authenticate.
  ///
  /// [SessionController] reacts by calling `logout()` and routing to Login.
  sessionExpired,
}

/// Singleton event bus that decouples [AuthInterceptor] (no Riverpod access)
/// from [SessionController] (presentation layer).
///
/// **Emitters** : [AuthInterceptor] — fires [tokenRefreshed] on silent
///   refresh success; fires [sessionExpired] when the refresh token is invalid
///   or the GoTrue refresh call fails.
///
/// **Consumers** : [SessionController] — subscribes in `build()` and reacts
///   by logging out or staying quiet.
class AuthEventBus {
  AuthEventBus._();

  static final AuthEventBus instance = AuthEventBus._();

  final StreamController<AuthEvent> _controller =
      StreamController<AuthEvent>.broadcast();

  /// Stream of [AuthEvent]s. Multiple listeners are supported.
  Stream<AuthEvent> get stream => _controller.stream;

  /// Emit an [event] to all current subscribers. Safe to call from any
  /// isolate; no-ops if the stream has already been closed.
  void emit(AuthEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }
}
