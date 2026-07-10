import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_requests.dart';

/// Concrete [AuthRepository] backed by [AuthRemoteDataSource].
///
/// Ready to sit in front of a PostgreSQL-persisted user table on the backend
/// -- this repository only knows about the REST contract, not the database.
/// Every method converts thrown [AppException]s into a [Result.failure] so
/// callers never need try/catch.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await _remoteDataSource.login(
        LoginRequest(email: email, password: password),
      );
      return Result<AuthTokens>.success(tokens.toEntity());
    } on AppException catch (e) {
      return Result<AuthTokens>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<User>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.register(
        RegisterRequest(fullName: fullName, email: email, password: password),
      );
      return Result<User>.success(user.toEntity());
    } on AppException catch (e) {
      return Result<User>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> logout({required String refreshToken}) async {
    try {
      await _remoteDataSource.logout(refreshToken);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<AuthTokens>> refreshSession({required String refreshToken}) async {
    try {
      final tokens = await _remoteDataSource.refresh(refreshToken);
      return Result<AuthTokens>.success(tokens.toEntity());
    } on AppException catch (e) {
      return Result<AuthTokens>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    try {
      await _remoteDataSource.forgotPassword(email);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        ResetPasswordRequest(resetToken: resetToken, newPassword: newPassword),
      );
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
