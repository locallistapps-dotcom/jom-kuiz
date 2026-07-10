import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/data/services/auth_service.dart';
import 'package:jom_kuiz/data/services/session_manager.dart';
import 'package:jom_kuiz/data/services/token_manager.dart';
import 'package:jom_kuiz/domain/entities/auth_tokens.dart';
import 'package:jom_kuiz/domain/entities/session_status.dart';
import 'package:jom_kuiz/domain/entities/user.dart';
import 'package:jom_kuiz/domain/repositories/auth_repository.dart';

import '../helpers/fake_token_storage.dart';

/// Scriptable [AuthRepository] fake -- lets tests drive [AuthService]
/// through both success and failure paths without a real backend.
class _FakeAuthRepository implements AuthRepository {
  Result<AuthTokens>? loginResult;
  Result<User>? registerResult;
  Result<void>? logoutResult;
  Result<AuthTokens>? refreshResult;

  String? lastLogoutRefreshToken;

  @override
  Future<Result<AuthTokens>> login({required String email, required String password}) async {
    return loginResult!;
  }

  @override
  Future<Result<User>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return registerResult!;
  }

  @override
  Future<Result<void>> logout({required String refreshToken}) async {
    lastLogoutRefreshToken = refreshToken;
    return logoutResult ?? const Result<void>.success(null);
  }

  @override
  Future<Result<AuthTokens>> refreshSession({required String refreshToken}) async {
    return refreshResult!;
  }

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    return const Result<void>.success(null);
  }
}

AuthTokens _tokens({bool expired = false}) {
  return AuthTokens(
    accessToken: 'access',
    refreshToken: 'refresh',
    accessTokenExpiresAt: expired
        ? DateTime.now().subtract(const Duration(minutes: 1))
        : DateTime.now().add(const Duration(minutes: 30)),
  );
}

void main() {
  late _FakeAuthRepository repository;
  late TokenManager tokenManager;
  late AuthService authService;

  setUp(() {
    repository = _FakeAuthRepository();
    tokenManager = TokenManager(FakeTokenStorage());
    authService = AuthService(
      repository: repository,
      tokenManager: tokenManager,
      sessionManager: SessionManager(tokenManager),
    );
  });

  test('login persists tokens on success', () async {
    repository.loginResult = Result<AuthTokens>.success(_tokens());

    final Result<void> result = await authService.login(email: 'a@b.com', password: 'password1');

    expect(result, isA<Success<void>>());
    expect(await tokenManager.readAccessToken(), 'access');
    expect(await tokenManager.hasValidSession, isTrue);
  });

  test('login does not persist tokens on failure', () async {
    repository.loginResult = const Result<AuthTokens>.failure(UnauthorizedFailure());

    final Result<void> result = await authService.login(email: 'a@b.com', password: 'wrong');

    expect(result, isA<ResultFailure<void>>());
    expect(await tokenManager.hasValidSession, isFalse);
  });

  test('logout clears local tokens even without an active session', () async {
    final Result<void> result = await authService.logout();

    expect(result, isA<Success<void>>());
    expect(repository.lastLogoutRefreshToken, isNull);
  });

  test('logout sends the refresh token and clears local tokens', () async {
    await tokenManager.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );

    await authService.logout();

    expect(repository.lastLogoutRefreshToken, 'refresh');
    expect(await tokenManager.hasValidSession, isFalse);
  });

  group('checkSession', () {
    test('is unauthenticated with no stored tokens', () async {
      expect(await authService.checkSession(), SessionStatus.unauthenticated);
    });

    test('is authenticated when the access token has not expired', () async {
      await tokenManager.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      expect(await authService.checkSession(), SessionStatus.authenticated);
    });

    test('silently refreshes an expired access token', () async {
      await tokenManager.saveTokens(
        accessToken: 'stale-access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      repository.refreshResult = Result<AuthTokens>.success(_tokens());

      expect(await authService.checkSession(), SessionStatus.authenticated);
      expect(await tokenManager.readAccessToken(), 'access');
    });

    test('clears the session when refresh fails', () async {
      await tokenManager.saveTokens(
        accessToken: 'stale-access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      repository.refreshResult = const Result<AuthTokens>.failure(UnauthorizedFailure());

      expect(await authService.checkSession(), SessionStatus.unauthenticated);
      expect(await tokenManager.hasValidSession, isFalse);
    });
  });
}
