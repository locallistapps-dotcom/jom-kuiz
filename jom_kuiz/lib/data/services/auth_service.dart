import '../../core/utils/result.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/session_status.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'session_manager.dart';
import 'token_manager.dart';

/// Orchestrates the Authentication feature's business flows.
///
/// This is the Service layer: it composes [AuthRepository] (pure API calls)
/// with [TokenManager] / [SessionManager] (local session persistence) so
/// that neither the domain layer nor the API layer needs to know about
/// token storage. [AuthController] (presentation layer) is the only caller.
class AuthService {
  AuthService({
    required AuthRepository repository,
    required TokenManager tokenManager,
    required SessionManager sessionManager,
  })  : _repository = repository,
        _tokenManager = tokenManager,
        _sessionManager = sessionManager;

  final AuthRepository _repository;
  final TokenManager _tokenManager;
  final SessionManager _sessionManager;

  /// Logs in and persists the resulting token pair.
  ///
  /// When `rememberMe` is `false`, the refresh token is kept in memory only
  /// (via [TokenManager]) instead of secure storage, so the session ends as
  /// soon as the app process ends rather than surviving a restart.
  Future<Result<void>> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final Result<AuthTokens> result = await _repository.login(email: email, password: password);
    return result.when(
      success: (AuthTokens tokens) async {
        await _tokenManager.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresAt: tokens.accessTokenExpiresAt,
          persistRefreshToken: rememberMe,
        );
        return const Result<void>.success(null);
      },
      failure: (failure) async => Result<void>.failure(failure),
    );
  }

  /// Registers a new parent account. Does not sign the user in -- per the
  /// module scope, the caller should route to Login after success.
  Future<Result<User>> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _repository.register(fullName: fullName, email: email, password: password);
  }

  /// Logs out locally regardless of whether the server-side call succeeds,
  /// since a user must always be able to sign out of the device.
  Future<Result<void>> logout() async {
    final String? refreshToken = await _tokenManager.readRefreshToken();

    Result<void> result = const Result<void>.success(null);
    if (refreshToken != null) {
      result = await _repository.logout(refreshToken: refreshToken);
    }

    await _sessionManager.endSession();
    return result;
  }

  Future<Result<void>> forgotPassword({required String email}) {
    return _repository.forgotPassword(email: email);
  }

  Future<Result<void>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    return _repository.resetPassword(resetToken: resetToken, newPassword: newPassword);
  }

  /// Determines the current [SessionStatus] for the splash screen / route
  /// guard, silently refreshing an expired access token when possible.
  Future<SessionStatus> checkSession() async {
    final bool hasSession = await _tokenManager.hasValidSession;
    if (!hasSession) return SessionStatus.unauthenticated;

    final bool expired = await _tokenManager.isAccessTokenExpired();
    if (!expired) return SessionStatus.authenticated;

    final String refreshToken = (await _tokenManager.readRefreshToken())!;
    final Result<AuthTokens> refreshResult = await _repository.refreshSession(
      refreshToken: refreshToken,
    );

    return refreshResult.when(
      success: (AuthTokens tokens) async {
        await _tokenManager.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresAt: tokens.accessTokenExpiresAt,
        );
        return SessionStatus.authenticated;
      },
      failure: (_) async {
        await _sessionManager.endSession();
        return SessionStatus.unauthenticated;
      },
    );
  }
}
