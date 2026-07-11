import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/subject_access.dart';
import '../../domain/repositories/subject_access_repository.dart';

/// Orchestrates subject access business rules.
///
/// Key rule: a parent's [SubjectAccess] records are implicitly inherited by
/// ALL children linked to that parent. The service exposes [checkChildAccess]
/// which resolves the parent from the child's profile and delegates to
/// [checkAccess].
class SubjectAccessService {
  const SubjectAccessService({required SubjectAccessRepository repo})
      : _repo = repo;

  final SubjectAccessRepository _repo;

  // ── Parent access ──────────────────────────────────────────────────────────

  Future<Result<List<SubjectAccess>>> getParentAccess(String parentId) =>
      _repo.getParentAccess(parentId);

  /// Returns `true` if [parentId] owns valid (non-expired) access to
  /// [subjectId].
  Future<Result<bool>> checkAccess({
    required String parentId,
    required String subjectId,
  }) =>
      _repo.checkAccess(parentId: parentId, subjectId: subjectId);

  /// Grants [subjectId] access to [parentId].
  ///
  /// Duplicate grants are silently ignored — the existing record is returned.
  Future<Result<SubjectAccess>> grantAccess({
    required String parentId,
    required String subjectId,
    SubjectAccessSource source = SubjectAccessSource.subscription,
    DateTime? expiresAt,
  }) =>
      _repo.grantAccess(
        parentId: parentId,
        subjectId: subjectId,
        source: source.name,
        expiresAt: expiresAt,
      );

  /// Grants access to every subject in [subjectIds] for [parentId].
  ///
  /// Used when activating a subscription package — grants all included
  /// subjects in one call. Errors are collected and returned as a list;
  /// successful grants still proceed even if some subjects fail.
  Future<List<String>> grantBulkAccess({
    required String parentId,
    required List<String> subjectIds,
    SubjectAccessSource source = SubjectAccessSource.subscription,
    DateTime? expiresAt,
  }) async {
    final List<String> errors = <String>[];
    for (final String subjectId in subjectIds) {
      final Result<SubjectAccess> result = await grantAccess(
        parentId: parentId,
        subjectId: subjectId,
        source: source,
        expiresAt: expiresAt,
      );
      result.when(
        success: (_) {},
        failure: (Failure f) => errors.add('$subjectId: ${f.message}'),
      );
    }
    return errors;
  }

  Future<Result<void>> revokeAccess(String accessId) =>
      _repo.revokeAccess(accessId);

  Future<Result<void>> revokeAccessBySubject({
    required String parentId,
    required String subjectId,
  }) =>
      _repo.revokeAccessBySubject(parentId: parentId, subjectId: subjectId);

  // ── Admin view ─────────────────────────────────────────────────────────────

  Future<Result<List<SubjectAccess>>> getAllAccess({String? parentId}) =>
      _repo.getAllAccess(parentId: parentId);
}
