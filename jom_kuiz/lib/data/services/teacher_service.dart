import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/teacher_dashboard.dart';
import '../../domain/repositories/teacher_repository.dart';

/// Orchestrates the Teacher module's dashboard flow.
///
/// Validates inputs before delegating to [TeacherRepository]. Only dashboard-
/// related methods are included here; attendance, homework, quiz, and
/// announcement methods will be added in later prompts.
class TeacherService {
  const TeacherService({required TeacherRepository repository})
      : _repository = repository;

  final TeacherRepository _repository;

  /// Returns the aggregated dashboard snapshot for [teacherId].
  ///
  /// Returns [ValidationFailure] immediately if [teacherId] is empty, so
  /// no network round-trip is made for obviously invalid requests.
  Future<Result<TeacherDashboard>> getDashboard(
      {required String teacherId}) {
    if (teacherId.trim().isEmpty) {
      return Future<Result<TeacherDashboard>>.value(
        const Result<TeacherDashboard>.failure(
          ValidationFailure(
              'Teacher ID must not be empty', 'TEACHER-002'),
        ),
      );
    }
    return _repository.getDashboard(teacherId: teacherId);
  }
}
