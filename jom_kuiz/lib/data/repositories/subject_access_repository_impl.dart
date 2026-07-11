import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/subject_access.dart';
import '../../domain/repositories/subject_access_repository.dart';
import '../datasources/subject_access_remote_data_source.dart';
import '../models/subscription_models.dart';

class SubjectAccessRepositoryImpl implements SubjectAccessRepository {
  const SubjectAccessRepositoryImpl(this._ds);

  final SubjectAccessRemoteDataSource _ds;

  @override
  Future<Result<List<SubjectAccess>>> getParentAccess(
      String parentId) async {
    try {
      final List<SubjectAccessModel> models =
          await _ds.getParentAccess(parentId);
      return Result<List<SubjectAccess>>.success(
          models.map((SubjectAccessModel m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<SubjectAccess>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<bool>> checkAccess({
    required String parentId,
    required String subjectId,
  }) async {
    try {
      return Result<bool>.success(
          await _ds.checkAccess(parentId: parentId, subjectId: subjectId));
    } on AppException catch (e) {
      return Result<bool>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<SubjectAccess>> grantAccess({
    required String parentId,
    required String subjectId,
    required String source,
    DateTime? expiresAt,
  }) async {
    try {
      final SubjectAccessModel model = await _ds.grantAccess(
        GrantAccessRequest(
          parentId: parentId,
          subjectId: subjectId,
          source: source,
          expiresAt: expiresAt,
        ),
      );
      return Result<SubjectAccess>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<SubjectAccess>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> revokeAccess(String accessId) async {
    try {
      await _ds.revokeAccess(accessId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> revokeAccessBySubject({
    required String parentId,
    required String subjectId,
  }) async {
    try {
      await _ds.revokeAccessBySubject(
          parentId: parentId, subjectId: subjectId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<List<SubjectAccess>>> getAllAccess({String? parentId}) async {
    try {
      final List<SubjectAccessModel> models =
          await _ds.getAllAccess(parentId: parentId);
      return Result<List<SubjectAccess>>.success(
          models.map((SubjectAccessModel m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<SubjectAccess>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
