import 'token_manager.dart';

/// Tracks the current session's high-level state (signed-in user id, session
/// validity) on top of [TokenManager]'s raw token storage.
///
/// Presentation-layer auth state (e.g. a Riverpod `AsyncNotifier`) should
/// wrap this class rather than duplicate its logic.
class SessionManager {
  SessionManager(this._tokenManager);

  final TokenManager _tokenManager;

  Future<bool> isSignedIn() => _tokenManager.hasValidSession;

  Future<void> endSession() => _tokenManager.clear();

  // TODO(auth): expose the current user id / profile once login writes it,
  // and a stream/notifier so widgets can react to sign-in/sign-out.
}
