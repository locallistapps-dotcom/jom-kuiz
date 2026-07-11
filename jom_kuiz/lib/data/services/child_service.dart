import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/entities/homework.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/child_repository.dart';

/// Orchestrates the Child module's business flows on top of [ChildRepository].
///
/// Thin for now — mostly pass-through — but provides the correct layer for
/// cross-cutting concerns (e.g. validation, caching, analytics hooks) that
/// future prompts may add without touching controllers or repositories.
class ChildService {
  const ChildService({required ChildRepository repository})
      : _repository = repository;

  final ChildRepository _repository;

  Future<Result<ChildProfile>> getProfile({required String childId}) {
    if (childId.trim().isEmpty) {
      return Future<Result<ChildProfile>>.value(
        const Result<ChildProfile>.failure(
          ValidationFailure('Child ID must not be empty', 'CHILD-002'),
        ),
      );
    }
    return _repository.getProfile(childId: childId);
  }

  Future<Result<ChildProfile>> updateProfile({
    required String childId,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? school,
    String? grade,
    String? bio,
  }) {
    if (fullName.trim().isEmpty) {
      return Future<Result<ChildProfile>>.value(
        const Result<ChildProfile>.failure(
          ValidationFailure('Full name is required', 'CHILD-002'),
        ),
      );
    }
    return _repository.updateProfile(
      childId: childId,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      school: school,
      grade: grade,
      bio: bio,
    );
  }

  Future<Result<ChildProfile>> updateAvatar({
    required String childId,
    required String localFilePath,
  }) =>
      _repository.updateAvatar(childId: childId, localFilePath: localFilePath);

  Future<Result<List<Homework>>> getHomework({required String childId}) =>
      _repository.getHomework(childId: childId);

  Future<Result<Homework>> getHomeworkDetail({required String homeworkId}) =>
      _repository.getHomeworkDetail(homeworkId: homeworkId);

  Future<Result<List<Quiz>>> getQuizList() => _repository.getQuizList();

  Future<Result<Quiz>> getQuizDetail({required String quizId}) =>
      _repository.getQuizDetail(quizId: quizId);

  Future<Result<QuizResult>> submitQuiz({
    required String quizId,
    required String childId,
    required Map<String, dynamic> answers,
    required int timeTakenSeconds,
  }) =>
      _repository.submitQuiz(
        quizId: quizId,
        childId: childId,
        answers: answers,
        timeTakenSeconds: timeTakenSeconds,
      );

  Future<Result<Achievement>> getAchievements({required String childId}) =>
      _repository.getAchievements(childId: childId);
}
