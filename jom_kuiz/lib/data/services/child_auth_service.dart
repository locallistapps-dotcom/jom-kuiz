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

      // Children authenticate via bcrypt (verify_child_credentials RPC) —
      // they do not have Supabase auth accounts and therefore receive no JWT.
      // The session is tracked by [currentChildIdProvider] alone.
      final String childId = data['child_id'] as String;
      return Result<String>.success(childId);
    } on AppException catch (e) {
      return Result<String>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
