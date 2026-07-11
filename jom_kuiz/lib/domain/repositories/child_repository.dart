import '../../core/utils/result.dart';
import '../entities/achievement.dart';
import '../entities/child_profile.dart';
import '../entities/homework.dart';
import '../entities/quiz.dart';

/// Child module repository contract implemented by [ChildRepositoryImpl].
///
/// API-facing only — no storage concerns leak into the domain layer.
/// All endpoints are documented with their corresponding REST paths.
abstract class ChildRepository {
  /// `GET /child/:childId/profile`
  Future<Result<ChildProfile>> getProfile({required String childId});

  /// `PUT /child/:childId/profile`
  Future<Result<ChildProfile>> updateProfile({
    required String childId,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? school,
    String? grade,
    String? bio,
  });

  /// `PUT /child/:childId/avatar`
  Future<Result<ChildProfile>> updateAvatar({
    required String childId,
    required String localFilePath,
  });

  /// `GET /child/:childId/homework`
  Future<Result<List<Homework>>> getHomework({required String childId});

  /// `GET /homework/:homeworkId`
  Future<Result<Homework>> getHomeworkDetail({required String homeworkId});

  /// `GET /quiz`
  Future<Result<List<Quiz>>> getQuizList();

  /// `GET /quiz/:quizId`
  Future<Result<Quiz>> getQuizDetail({required String quizId});

  /// `POST /quiz/:quizId/submit`
  Future<Result<QuizResult>> submitQuiz({
    required String quizId,
    required String childId,
    required Map<String, dynamic> answers,
    required int timeTakenSeconds,
  });

  /// `GET /child/:childId/achievements`
  Future<Result<Achievement>> getAchievements({required String childId});
}
