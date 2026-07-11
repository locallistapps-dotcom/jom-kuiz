import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/entities/homework.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/child_repository.dart';
import '../datasources/child_remote_data_source.dart';
import '../models/child_requests.dart';

/// Concrete [ChildRepository] backed by [ChildRemoteDataSource].
class ChildRepositoryImpl implements ChildRepository {
  const ChildRepositoryImpl(this._remoteDataSource);

  final ChildRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ChildProfile>> getProfile({required String childId}) async {
    try {
      final model = await _remoteDataSource.getProfile(childId: childId);
      return Result<ChildProfile>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<ChildProfile>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ChildProfile>> updateProfile({
    required String childId,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bio,
  }) async {
    try {
      final model = await _remoteDataSource.updateProfile(
        childId: childId,
        request: UpdateChildProfileRequest(
          fullName: fullName,
          dateOfBirth: dateOfBirth,
          gender: gender,
          bio: bio,
        ),
      );
      return Result<ChildProfile>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<ChildProfile>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ChildProfile>> updateAvatar({
    required String childId,
    required String localFilePath,
  }) async {
    try {
      final model = await _remoteDataSource.updateAvatar(
        childId: childId,
        request: UpdateChildAvatarRequest(localFilePath: localFilePath),
      );
      return Result<ChildProfile>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<ChildProfile>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<List<Homework>>> getHomework({required String childId}) async {
    try {
      final models = await _remoteDataSource.getHomework(childId: childId);
      return Result<List<Homework>>.success(
          models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<Homework>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Homework>> getHomeworkDetail(
      {required String homeworkId}) async {
    try {
      final model =
          await _remoteDataSource.getHomeworkDetail(homeworkId: homeworkId);
      return Result<Homework>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Homework>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<List<Quiz>>> getQuizList() async {
    try {
      final models = await _remoteDataSource.getQuizList();
      return Result<List<Quiz>>.success(
          models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<Quiz>>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Quiz>> getQuizDetail({required String quizId}) async {
    try {
      final model = await _remoteDataSource.getQuizDetail(quizId: quizId);
      return Result<Quiz>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Quiz>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<QuizResult>> submitQuiz({
    required String quizId,
    required String childId,
    required Map<String, dynamic> answers,
    required int timeTakenSeconds,
  }) async {
    try {
      final model = await _remoteDataSource.submitQuiz(
        SubmitQuizRequest(
          quizId: quizId,
          childId: childId,
          answers: answers,
          timeTakenSeconds: timeTakenSeconds,
        ),
      );
      return Result<QuizResult>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<QuizResult>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Achievement>> getAchievements(
      {required String childId}) async {
    try {
      final model =
          await _remoteDataSource.getAchievements(childId: childId);
      return Result<Achievement>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Achievement>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
