import '../../core/error/failure.dart';
import '../../core/error/subject_error_codes.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';

/// Orchestrates Subject business flows on top of [SubjectRepository].
///
/// Handles input validation before delegating to the repository so that the
/// controller layer never talks to the repository directly.
class SubjectService {
  const SubjectService({required SubjectRepository repository})
      : _repository = repository;

  final SubjectRepository _repository;

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Result<List<Subject>>> getSubjects({
    String? search,
    SubjectSortOrder sortOrder = SubjectSortOrder.nameAsc,
    bool? isActive,
  }) {
    return _repository.getSubjects(
      search: search?.trim().isEmpty ?? true ? null : search?.trim(),
      sortOrder: sortOrder,
      isActive: isActive,
    );
  }

  Future<Result<Subject>> getSubjectById({required String subjectId}) {
    if (subjectId.trim().isEmpty) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure('Subject ID must not be empty',
              SubjectErrorCodes.invalidSubjectData),
        ),
      );
    }
    return _repository.getSubjectById(subjectId: subjectId);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Subject>> createSubject({
    required String subjectName,
    String? description,
    String? icon,
    int displayOrder = 0,
  }) {
    final String name = subjectName.trim();
    if (name.isEmpty) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure(
            'Subject name is required',
            SubjectErrorCodes.invalidSubjectData,
          ),
        ),
      );
    }
    if (name.length > 100) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure(
            'Subject name must not exceed 100 characters',
            SubjectErrorCodes.invalidSubjectData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            SubjectErrorCodes.invalidSubjectData,
          ),
        ),
      );
    }
    return _repository.createSubject(
      subjectName: name,
      description: description?.trim().isEmpty ?? true
          ? null
          : description?.trim(),
      icon: icon?.trim().isEmpty ?? true ? null : icon?.trim(),
      displayOrder: displayOrder,
    );
  }

  Future<Result<Subject>> updateSubject({
    required String subjectId,
    required String subjectName,
    String? description,
    String? icon,
    required int displayOrder,
    required bool isActive,
  }) {
    final String name = subjectName.trim();
    if (subjectId.trim().isEmpty) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure('Subject ID must not be empty',
              SubjectErrorCodes.invalidSubjectData),
        ),
      );
    }
    if (name.isEmpty) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure(
            'Subject name is required',
            SubjectErrorCodes.invalidSubjectData,
          ),
        ),
      );
    }
    if (name.length > 100) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure(
            'Subject name must not exceed 100 characters',
            SubjectErrorCodes.invalidSubjectData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            SubjectErrorCodes.invalidSubjectData,
          ),
        ),
      );
    }
    return _repository.updateSubject(
      subjectId: subjectId,
      subjectName: name,
      description: description?.trim().isEmpty ?? true
          ? null
          : description?.trim(),
      icon: icon?.trim().isEmpty ?? true ? null : icon?.trim(),
      displayOrder: displayOrder,
      isActive: isActive,
    );
  }

  Future<Result<void>> deleteSubject({required String subjectId}) {
    if (subjectId.trim().isEmpty) {
      return Future<Result<void>>.value(
        const Result<void>.failure(
          ValidationFailure('Subject ID must not be empty',
              SubjectErrorCodes.invalidSubjectData),
        ),
      );
    }
    return _repository.deleteSubject(subjectId: subjectId);
  }

  Future<Result<Subject>> toggleActive({
    required String subjectId,
    required bool isActive,
  }) {
    if (subjectId.trim().isEmpty) {
      return Future<Result<Subject>>.value(
        const Result<Subject>.failure(
          ValidationFailure('Subject ID must not be empty',
              SubjectErrorCodes.invalidSubjectData),
        ),
      );
    }
    return _repository.toggleActive(subjectId: subjectId, isActive: isActive);
  }
}
