import '../../core/utils/result.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';

/// Authentication contract implemented by [AuthRepositoryImpl].
///
/// This interface is purely API-facing: it exchanges credentials/tokens with
/// the backend and maps failures, but never touches local token storage --
/// that is [AuthService]'s responsibility. This keeps the repository ready
/// to back onto any REST backend (PostgreSQL-persisted users, per the
/// project's data store) without leaking storage concerns into the domain
/// layer.
abstract class AuthRepository {
  /// `POST /auth/login`
  Future<Result<AuthTokens>> login({
    required String email,
    required String password,
  });

  /// `POST /auth/register`
  Future<Result<User>> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// `POST /auth/logout`
  Future<Result<void>> logout({required String refreshToken});

  /// `POST /auth/refresh`
  Future<Result<AuthTokens>> refreshSession({required String refreshToken});

  /// `POST /auth/forgot-password`
  Future<Result<void>> forgotPassword({required String email});

  /// `POST /auth/reset-password`
  Future<Result<void>> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}
