import '../../core/utils/result.dart';
import '../entities/subject.dart';

/// Abstract contract for Subject CRUD operations.
///
/// The implementation is backed by Supabase REST (PostgREST) via the shared
/// Dio instance. All methods return [Result] — no exceptions escape this layer.
abstract interface class SubjectRepository {
  /// Returns the full subject list, optionally filtered by [search] text and
  /// sorted according to [sortOrder]. Pass [isActive] to restrict to active
  /// or inactive subjects only.
  Future<Result<List<Subject>>> getSubjects({
    String? search,
    SubjectSortOrder sortOrder = SubjectSortOrder.nameAsc,
    bool? isActive,
  });

  /// Returns a single subject by primary key.
  Future<Result<Subject>> getSubjectById({required String subjectId});

  /// Creates a new subject. [displayOrder] defaults to 0 if not provided.
  Future<Result<Subject>> createSubject({
    required String subjectName,
    String? description,
    String? icon,
    int displayOrder,
  });

  /// Updates all mutable fields of an existing subject.
  Future<Result<Subject>> updateSubject({
    required String subjectId,
    required String subjectName,
    String? description,
    String? icon,
    required int displayOrder,
    required bool isActive,
  });

  /// Hard-deletes a subject. Returns [Result.success] with `null` on success.
  Future<Result<void>> deleteSubject({required String subjectId});

  /// Flips [Subject.isActive] to [isActive] for the given [subjectId].
  Future<Result<Subject>> toggleActive({
    required String subjectId,
    required bool isActive,
  });
}
