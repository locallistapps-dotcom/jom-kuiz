import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/data/services/child_service.dart';
import 'package:jom_kuiz/domain/entities/achievement.dart';
import 'package:jom_kuiz/domain/entities/child_profile.dart';
import 'package:jom_kuiz/domain/entities/homework.dart';
import 'package:jom_kuiz/domain/entities/quiz.dart';
import 'package:jom_kuiz/domain/repositories/child_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeChildRepository implements ChildRepository {
  Result<ChildProfile>? getProfileResult;
  Result<ChildProfile>? updateProfileResult;
  Result<ChildProfile>? updateAvatarResult;
  Result<List<Homework>>? getHomeworkResult;
  Result<Homework>? getHomeworkDetailResult;
  Result<List<Quiz>>? getQuizListResult;
  Result<Quiz>? getQuizDetailResult;
  Result<QuizResult>? submitQuizResult;
  Result<Achievement>? getAchievementsResult;

  @override
  Future<Result<ChildProfile>> getProfile({required String childId}) async =>
      getProfileResult!;

  @override
  Future<Result<ChildProfile>> updateProfile({
    required String childId,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? school,
    String? grade,
    String? bio,
  }) async =>
      updateProfileResult!;

  @override
  Future<Result<ChildProfile>> updateAvatar({
    required String childId,
    required String localFilePath,
  }) async =>
      updateAvatarResult!;

  @override
  Future<Result<List<Homework>>> getHomework({required String childId}) async =>
      getHomeworkResult!;

  @override
  Future<Result<Homework>> getHomeworkDetail(
          {required String homeworkId}) async =>
      getHomeworkDetailResult!;

  @override
  Future<Result<List<Quiz>>> getQuizList() async => getQuizListResult!;

  @override
  Future<Result<Quiz>> getQuizDetail({required String quizId}) async =>
      getQuizDetailResult!;

  @override
  Future<Result<QuizResult>> submitQuiz({
    required String quizId,
    required String childId,
    required Map<String, dynamic> answers,
    required int timeTakenSeconds,
  }) async =>
      submitQuizResult!;

  @override
  Future<Result<Achievement>> getAchievements({required String childId}) async =>
      getAchievementsResult!;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final DateTime _ts = DateTime(2026, 1, 1);

ChildProfile _profile() => ChildProfile(
      childId: 'c1',
      fullName: 'Ahmad',
      username: 'ahmad123',
      createdAt: _ts,
      updatedAt: _ts,
    );

Achievement _achievement() => Achievement(
      childId: 'c1',
      totalPoints: 120,
      ranking: 5,
      stars: 3,
      badges: const <Badge>[],
      recentResults: const <QuizResult>[],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeChildRepository repository;
  late ChildService service;

  setUp(() {
    repository = _FakeChildRepository();
    service = ChildService(repository: repository);
  });

  // ── getProfile ─────────────────────────────────────────────────────────────

  group('getProfile', () {
    test('passes through a successful result', () async {
      repository.getProfileResult = Result<ChildProfile>.success(_profile());

      final Result<ChildProfile> result =
          await service.getProfile(childId: 'c1');

      expect(result, isA<Success<ChildProfile>>());
    });

    test('returns ValidationFailure when childId is empty', () async {
      final Result<ChildProfile> result =
          await service.getProfile(childId: '');

      expect(result, isA<ResultFailure<ChildProfile>>());
      final failure = (result as ResultFailure<ChildProfile>).failure;
      expect(failure, isA<ValidationFailure>());
    });

    test('returns ValidationFailure for whitespace-only childId', () async {
      final Result<ChildProfile> result =
          await service.getProfile(childId: '   ');

      expect(result, isA<ResultFailure<ChildProfile>>());
    });

    test('passes through a failure from the repository', () async {
      repository.getProfileResult =
          const Result<ChildProfile>.failure(ServerFailure('not found'));

      final Result<ChildProfile> result =
          await service.getProfile(childId: 'c1');

      expect(result, isA<ResultFailure<ChildProfile>>());
    });
  });

  // ── updateProfile ──────────────────────────────────────────────────────────

  group('updateProfile', () {
    test('passes through a successful update', () async {
      repository.updateProfileResult =
          Result<ChildProfile>.success(_profile());

      final Result<ChildProfile> result = await service.updateProfile(
          childId: 'c1', fullName: 'Ahmad Updated');

      expect(result, isA<Success<ChildProfile>>());
    });

    test('returns ValidationFailure when fullName is empty', () async {
      final Result<ChildProfile> result =
          await service.updateProfile(childId: 'c1', fullName: '');

      expect(result, isA<ResultFailure<ChildProfile>>());
      final failure = (result as ResultFailure<ChildProfile>).failure;
      expect(failure, isA<ValidationFailure>());
    });
  });

  // ── getHomework ────────────────────────────────────────────────────────────

  group('getHomework', () {
    test('passes through an empty list on success', () async {
      repository.getHomeworkResult =
          const Result<List<Homework>>.success(<Homework>[]);

      final Result<List<Homework>> result =
          await service.getHomework(childId: 'c1');

      expect((result as Success<List<Homework>>).data, isEmpty);
    });
  });

  // ── getQuizList ────────────────────────────────────────────────────────────

  group('getQuizList', () {
    test('passes through an empty list on success', () async {
      repository.getQuizListResult =
          const Result<List<Quiz>>.success(<Quiz>[]);

      final Result<List<Quiz>> result = await service.getQuizList();

      expect((result as Success<List<Quiz>>).data, isEmpty);
    });
  });

  // ── getAchievements ────────────────────────────────────────────────────────

  group('getAchievements', () {
    test('passes through an achievement on success', () async {
      repository.getAchievementsResult =
          Result<Achievement>.success(_achievement());

      final Result<Achievement> result =
          await service.getAchievements(childId: 'c1');

      expect((result as Success<Achievement>).data.totalPoints, 120);
    });
  });

  // ── submitQuiz ─────────────────────────────────────────────────────────────

  group('submitQuiz', () {
    test('passes through the quiz result on success', () async {
      repository.submitQuizResult = Result<QuizResult>.success(
        QuizResult(
          resultId: 'r1',
          quizId: 'q1',
          quizTitle: 'Maths Quiz',
          childId: 'c1',
          score: 8,
          totalQuestions: 10,
          completedAt: _ts,
          timeTakenSeconds: 300,
        ),
      );

      final Result<QuizResult> result = await service.submitQuiz(
        quizId: 'q1',
        childId: 'c1',
        answers: const <String, dynamic>{},
        timeTakenSeconds: 300,
      );

      expect(result, isA<Success<QuizResult>>());
      expect((result as Success<QuizResult>).data.score, 8);
    });

    test('passes through a failure result', () async {
      repository.submitQuizResult =
          const Result<QuizResult>.failure(ServerFailure('rejected'));

      final Result<QuizResult> result = await service.submitQuiz(
        quizId: 'q1',
        childId: 'c1',
        answers: const <String, dynamic>{},
        timeTakenSeconds: 0,
      );

      expect(result, isA<ResultFailure<QuizResult>>());
    });
  });
}
