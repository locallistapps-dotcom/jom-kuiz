import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../datasources/subject_remote_data_source.dart';
import '../models/subject_model.dart';

/// Concrete [SubjectRepository] backed by [SubjectRemoteDataSource].
///
/// Converts [AppException]s from the datasource into [Failure]s via
/// [GlobalExceptionHandler] so the presentation layer stays exception-free.
class SubjectRepositoryImpl implements SubjectRepository {
  const SubjectRepositoryImpl(this._remoteDataSource);

  final SubjectRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Subject>>> getSubjects({
    String? search,
    SubjectSortOrder sortOrder = SubjectSortOrder.nameAsc,
    bool? isActive,
  }) async {
    try {
      final List<SubjectModel> models = await _remoteDataSource.getSubjects(
        search: search,
        sortOrder: sortOrder,
        isActive: isActive,
      );
      return Result<List<Subject>>.success(
        models.map((SubjectModel m) => m.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Result<List<Subject>>.failure(
        GlobalExceptionHandler.toFailure(e),
      );
    }
  }

  @override
  Future<Result<Subject>> getSubjectById({required String subjectId}) async {
    try {
      final SubjectModel model =
          await _remoteDataSource.getSubjectById(subjectId: subjectId);
      return Result<Subject>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Subject>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Subject>> createSubject({
    required String subjectName,
    String? description,
    String? icon,
    int displayOrder = 0,
  }) async {
    try {
      final SubjectModel model = await _remoteDataSource.createSubject(
        CreateSubjectRequest(
          subjectName: subjectName,
          description: description,
          icon: icon,
          displayOrder: displayOrder,
        ),
      );
      return Result<Subject>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Subject>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Subject>> updateSubject({
    required String subjectId,
    required String subjectName,
    String? description,
    String? icon,
    required int displayOrder,
    required bool isActive,
  }) async {
    try {
      final SubjectModel model = await _remoteDataSource.updateSubject(
        subjectId: subjectId,
        request: UpdateSubjectRequest(
          subjectName: subjectName,
          description: description,
          icon: icon,
          displayOrder: displayOrder,
          isActive: isActive,
        ),
      );
      return Result<Subject>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Subject>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteSubject({required String subjectId}) async {
    try {
      await _remoteDataSource.deleteSubject(subjectId: subjectId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Subject>> toggleActive({
    required String subjectId,
    required bool isActive,
  }) async {
    try {
      final SubjectModel model = await _remoteDataSource.toggleActive(
        subjectId: subjectId,
        request: ToggleSubjectActiveRequest(isActive: isActive),
      );
      return Result<Subject>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Subject>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
