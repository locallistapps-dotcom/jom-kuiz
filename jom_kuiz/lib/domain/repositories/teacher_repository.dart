import '../../core/utils/result.dart';
import '../entities/teacher_dashboard.dart';

/// Contract for all Teacher module data operations.
///
/// Only methods required by the Teacher Dashboard are declared here.
/// Attendance, homework, quiz, and announcement methods will be added
/// in later prompts as those modules ship.
abstract class TeacherRepository {
  /// Fetches the aggregated dashboard snapshot for [teacherId].
  Future<Result<TeacherDashboard>> getDashboard({required String teacherId});
}
