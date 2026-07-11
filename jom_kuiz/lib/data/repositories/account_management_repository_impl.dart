import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../data/models/account_management_models.dart';
import '../../data/models/account_management_requests.dart';
import '../../domain/entities/education_level.dart';
import '../../domain/repositories/account_management_repository.dart';
import '../datasources/account_management_remote_data_source.dart';

class AccountManagementRepositoryImpl implements AccountManagementRepository {
  const AccountManagementRepositoryImpl(this._ds);

  final AccountManagementRemoteDataSource _ds;

  @override
  Future<Result<List<ChildManagementModel>>> getChildren() async {
    try {
      return Result<List<ChildManagementModel>>.success(
          await _ds.getChildren());
    } on AppException catch (e) {
      return Result<List<ChildManagementModel>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ChildManagementModel>> getChild(String childId) async {
    try {
      return Result<ChildManagementModel>.success(await _ds.getChild(childId));
    } on AppException catch (e) {
      return Result<ChildManagementModel>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ChildManagementModel>> createChild({
    required String fullName,
    required String username,
    required String password,
    required EducationLevel educationLevel,
    required String yearGrade,
  }) async {
    try {
      return Result<ChildManagementModel>.success(
        await _ds.createChild(
          CreateChildRequest(
            fullName: fullName,
            username: username,
            password: password,
            educationLevel: educationLevel.name,
            yearGrade: yearGrade,
          ),
        ),
      );
    } on AppException catch (e) {
      return Result<ChildManagementModel>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ChildManagementModel>> updateChild({
    required String childId,
    required String fullName,
    required String username,
    String? password,
    required EducationLevel educationLevel,
    required String yearGrade,
  }) async {
    try {
      return Result<ChildManagementModel>.success(
        await _ds.updateChild(
          childId,
          UpdateChildRequest(
            fullName: fullName,
            username: username,
            password: password,
            educationLevel: educationLevel.name,
            yearGrade: yearGrade,
          ),
        ),
      );
    } on AppException catch (e) {
      return Result<ChildManagementModel>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ChildManagementModel>> setChildStatus({
    required String childId,
    required ChildAccountStatus status,
  }) async {
    try {
      return Result<ChildManagementModel>.success(
        await _ds.setChildStatus(
          childId,
          SetChildStatusRequest(accountStatus: status.name),
        ),
      );
    } on AppException catch (e) {
      return Result<ChildManagementModel>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> resetChildPassword({
    required String childId,
    required String newPassword,
  }) async {
    try {
      await _ds.resetChildPassword(
          ResetChildPasswordRequest(childId: childId, newPassword: newPassword));
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<bool>> isUsernameAvailable(String username) async {
    try {
      return Result<bool>.success(await _ds.isUsernameAvailable(username));
    } on AppException catch (e) {
      return Result<bool>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteChild({required String childId}) async {
    try {
      await _ds.deleteChild(childId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
