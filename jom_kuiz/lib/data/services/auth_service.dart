import '../../core/logger/app_logger.dart';
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
  ///
  /// Guaranteed to complete within 8 seconds — times out to
  /// [SessionStatus.unauthenticated] so the splash screen never hangs
  /// forever (e.g. when flutter_secure_storage or the network stalls on web).
  Future<SessionStatus> checkSession() async {
    try {
      return await _doCheckSession().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          AppLogger.instance.warning(
            'checkSession timed out after 8 s — continuing as unauthenticated',
          );
          return SessionStatus.unauthenticated;
        },
      );
    } catch (e, st) {
      AppLogger.instance.error(
        'checkSession threw unexpectedly — continuing as unauthenticated',
        error: e,
        stackTrace: st,
      );
      return SessionStatus.unauthenticated;
    }
  }

  Future<SessionStatus> _doCheckSession() async {
    final bool hasSession = await _tokenManager.hasValidSession;
    if (!hasSession) {
      AppLogger.instance.debug('checkSession: no stored session');
      return SessionStatus.unauthenticated;
    }

    final bool expired = await _tokenManager.isAccessTokenExpired();
    if (!expired) {
      AppLogger.instance.debug('checkSession: access token still valid');
      return SessionStatus.authenticated;
    }

    AppLogger.instance.debug('checkSession: access token expired, attempting silent refresh');
    final String? refreshToken = await _tokenManager.readRefreshToken();
    if (refreshToken == null) {
      AppLogger.instance.warning('checkSession: no refresh token, ending session');
      await _sessionManager.endSession();
      return SessionStatus.unauthenticated;
    }

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
        AppLogger.instance.debug('checkSession: silent refresh succeeded');
        return SessionStatus.authenticated;
      },
      failure: (f) async {
        AppLogger.instance.warning('checkSession: silent refresh failed — ${f.message}');
        await _sessionManager.endSession();
        return SessionStatus.unauthenticated;
      },
    );
  }
}
