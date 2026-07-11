import '../../core/utils/result.dart';
import '../entities/subject_access.dart';

/// Contract for managing parent subject access records.
///
/// Children inherit access automatically — the service layer resolves child
/// access by looking up their linked parent's [SubjectAccess] rows.
abstract interface class SubjectAccessRepository {
  /// Returns all [SubjectAccess] records for [parentId].
  Future<Result<List<SubjectAccess>>> getParentAccess(String parentId);

  /// Returns `true` if [parentId] has valid access to [subjectId].
  Future<Result<bool>> checkAccess({
    required String parentId,
    required String subjectId,
  });

  /// Grants access to [subjectId] for [parentId].
  ///
  /// Duplicate records are silently ignored (server enforces UNIQUE constraint).
  Future<Result<SubjectAccess>> grantAccess({
    required String parentId,
    required String subjectId,
    required String source,
    DateTime? expiresAt,
  });

  /// Revokes a specific access record by [accessId].
  Future<Result<void>> revokeAccess(String accessId);

  /// Revokes all access for [parentId] on [subjectId].
  Future<Result<void>> revokeAccessBySubject({
    required String parentId,
    required String subjectId,
  });

  /// Admin view — all access records with optional [parentId] filter.
  Future<Result<List<SubjectAccess>>> getAllAccess({String? parentId});
}
