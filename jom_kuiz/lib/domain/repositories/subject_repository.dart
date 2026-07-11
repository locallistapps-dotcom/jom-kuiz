import '../../core/utils/result.dart';
import '../entities/subject.dart';

/// Abstract contract for subject catalogue operations.
abstract interface class SubjectRepository {
  /// Returns all available subjects.
  Future<Result<List<Subject>>> getSubjects();

  /// Returns a single subject by [subjectId].
  Future<Result<Subject>> getSubjectById({required String subjectId});
}
