import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../datasources/account_management_remote_data_source.dart';
import '../services/token_manager.dart';

/// Handles child login — separate from the parent [AuthService] so the
/// existing auth layer is not modified.
///
/// Flow:
/// 1. Call `POST /auth/child/login` via [AccountManagementRemoteDataSource].
/// 2. Save the returned token pair via [TokenManager].
/// 3. Return the `child_id` string so the caller can set
///    [currentChildIdProvider].
class ChildAuthService {
  const ChildAuthService({
    required AccountManagementRemoteDataSource dataSource,
    required TokenManager tokenManager,
  })  : _dataSource = dataSource,
        _tokenManager = tokenManager;

  final AccountManagementRemoteDataSource _dataSource;
  final TokenManager _tokenManager;

  Future<Result<String>> loginChild({
    required String studentId,
    required String username,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> data = await _dataSource.loginChild(
        studentId: studentId,
        username: username,
        password: password,
      );

      final String accessToken = data['access_token'] as String;
      final String refreshToken = data['refresh_token'] as String;
      final int expiresIn = (data['expires_in'] as int?) ?? 3600;
      final String childId = data['child_id'] as String;

      await _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        persistRefreshToken: true,
      );

      return Result<String>.success(childId);
    } on AppException catch (e) {
      return Result<String>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
