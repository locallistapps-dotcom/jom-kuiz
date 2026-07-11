import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/di/providers.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/achievement.dart';
import 'package:jom_kuiz/domain/entities/child_profile.dart';
import 'package:jom_kuiz/domain/entities/homework.dart';
import 'package:jom_kuiz/domain/entities/quiz.dart';
import 'package:jom_kuiz/domain/repositories/child_repository.dart';
import 'package:jom_kuiz/presentation/controllers/child_profile_controller.dart';
import 'package:jom_kuiz/presentation/controllers/homework_controller.dart';
import 'package:jom_kuiz/presentation/controllers/quiz_controller.dart';
import 'package:jom_kuiz/presentation/providers/child_providers.dart';

import '../helpers/fake_token_storage.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeChildRepository implements ChildRepository {
  Result<ChildProfile>? getProfileResult;
  Result<ChildProfile>? updateProfileResult;
  Result<List<Homework>>? getHomeworkResult;
  Result<List<Quiz>>? getQuizListResult;

  @override
  Future<Result<ChildProfile>> getProfile({required String childId}) async =>
      getProfileResult ?? const Result<ChildProfile>.failure(ServerFailure());

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
      throw UnimplementedError();

  @override
  Future<Result<List<Homework>>> getHomework({required String childId}) async =>
      getHomeworkResult ?? const Result<List<Homework>>.success(<Homework>[]);

  @override
  Future<Result<Homework>> getHomeworkDetail(
          {required String homeworkId}) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Quiz>>> getQuizList() async =>
      getQuizListResult ?? const Result<List<Quiz>>.success(<Quiz>[]);

  @override
  Future<Result<Quiz>> getQuizDetail({required String quizId}) async =>
      throw UnimplementedError();

  @override
  Future<Result<QuizResult>> submitQuiz({
    required String quizId,
    required String childId,
    required Map<String, dynamic> answers,
    required int timeTakenSeconds,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<Achievement>> getAchievements({required String childId}) async =>
      throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final DateTime _ts = DateTime(2026, 1, 1);

ChildProfile _profile({String fullName = 'Ahmad'}) => ChildProfile(
      childId: 'c1',
      fullName: fullName,
      username: 'ahmad123',
      createdAt: _ts,
      updatedAt: _ts,
    );

/// Builds a [ProviderContainer] with:
///   - [tokenStorageProvider] → [FakeTokenStorage] (no flutter_secure_storage)
///   - [childRepositoryProvider] → fake for behaviour control
///   - [currentChildIdProvider] pre-seeded with 'c1'
ProviderContainer _buildContainer(_FakeChildRepository repo,
    {String childId = 'c1'}) {
  return ProviderContainer(
    overrides: <Override>[
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      childRepositoryProvider.overrideWithValue(repo),
      currentChildIdProvider.overrideWith((ref) => childId),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeChildRepository repository;

  setUp(() {
    repository = _FakeChildRepository();
  });

  // ── ChildProfileController ─────────────────────────────────────────────────

  group('ChildProfileController', () {
    test('build() loads the profile when childId is set', () async {
      repository.getProfileResult =
          Result<ChildProfile>.success(_profile());
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      final ChildProfile? profile =
          await container.read(childProfileControllerProvider.future);

      expect(profile?.fullName, 'Ahmad');
    });

    test('build() returns null when childId is empty', () async {
      final container = _buildContainer(repository, childId: '');
      addTearDown(container.dispose);

      final ChildProfile? profile =
          await container.read(childProfileControllerProvider.future);

      expect(profile, isNull);
    });

    test('build() surfaces failure as AsyncError', () async {
      repository.getProfileResult =
          const Result<ChildProfile>.failure(ServerFailure('not found'));
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      await expectLater(
        container.read(childProfileControllerProvider.future),
        throwsA(isA<Failure>()),
      );
    });

    test('updateProfile updates state on success', () async {
      repository.getProfileResult =
          Result<ChildProfile>.success(_profile());
      repository.updateProfileResult =
          Result<ChildProfile>.success(_profile(fullName: 'Ahmad Updated'));
      final container = _buildContainer(repository);
      addTearDown(container.dispose);
      await container.read(childProfileControllerProvider.future);

      final result = await container
          .read(childProfileControllerProvider.notifier)
          .updateProfile(fullName: 'Ahmad Updated');

      expect(result, isA<Success<ChildProfile>>());
      expect(
        container.read(childProfileControllerProvider).valueOrNull?.fullName,
        'Ahmad Updated',
      );
    });

    test('updateProfile failure leaves prior state intact', () async {
      repository.getProfileResult =
          Result<ChildProfile>.success(_profile());
      repository.updateProfileResult =
          const Result<ChildProfile>.failure(ValidationFailure('bad input'));
      final container = _buildContainer(repository);
      addTearDown(container.dispose);
      await container.read(childProfileControllerProvider.future);

      final result = await container
          .read(childProfileControllerProvider.notifier)
          .updateProfile(fullName: 'Ahmad Updated');

      expect(result, isA<ResultFailure<ChildProfile>>());
      // Prior data must survive the failed mutation.
      expect(
        container.read(childProfileControllerProvider).valueOrNull?.fullName,
        'Ahmad',
      );
      expect(container.read(childProfileControllerProvider).hasError, isFalse);
    });
  });

  // ── HomeworkController ─────────────────────────────────────────────────────

  group('HomeworkController', () {
    test('build() returns an empty list when no homework exists', () async {
      repository.getHomeworkResult =
          const Result<List<Homework>>.success(<Homework>[]);
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      final List<Homework> list =
          await container.read(homeworkControllerProvider.future);

      expect(list, isEmpty);
    });

    test('pending getter returns only non-completed homework', () async {
      final DateTime due = DateTime(2026, 6, 1);
      final Homework hw1 = Homework(
        homeworkId: 'hw1',
        childId: 'c1',
        title: 'Maths',
        subject: 'Maths',
        dueDate: due,
        status: HomeworkStatus.pending,
        createdAt: _ts,
      );
      final Homework hw2 = Homework(
        homeworkId: 'hw2',
        childId: 'c1',
        title: 'Science',
        subject: 'Science',
        dueDate: due,
        status: HomeworkStatus.completed,
        createdAt: _ts,
      );
      repository.getHomeworkResult =
          Result<List<Homework>>.success(<Homework>[hw1, hw2]);
      final container = _buildContainer(repository);
      addTearDown(container.dispose);
      await container.read(homeworkControllerProvider.future);

      final List<Homework> pending =
          container.read(homeworkControllerProvider.notifier).pending;

      expect(pending.length, 1);
      expect(pending.first.homeworkId, 'hw1');
    });

    test('completed getter returns only completed homework', () async {
      final DateTime due = DateTime(2026, 5, 1);
      final DateTime completedAt = DateTime(2026, 5, 1);
      final Homework hw = Homework(
        homeworkId: 'hw1',
        childId: 'c1',
        title: 'History',
        subject: 'History',
        dueDate: due,
        status: HomeworkStatus.completed,
        completedAt: completedAt,
        createdAt: _ts,
      );
      repository.getHomeworkResult =
          Result<List<Homework>>.success(<Homework>[hw]);
      final container = _buildContainer(repository);
      addTearDown(container.dispose);
      await container.read(homeworkControllerProvider.future);

      final List<Homework> completed =
          container.read(homeworkControllerProvider.notifier).completed;

      expect(completed.length, 1);
      expect(completed.first.homeworkId, 'hw1');
    });
  });

  // ── QuizController ─────────────────────────────────────────────────────────

  group('QuizController', () {
    test('build() returns an empty list when no quizzes exist', () async {
      repository.getQuizListResult =
          const Result<List<Quiz>>.success(<Quiz>[]);
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      final List<Quiz> list =
          await container.read(quizControllerProvider.future);

      expect(list, isEmpty);
    });

    test('build() surfaces failure as AsyncError', () async {
      repository.getQuizListResult =
          const Result<List<Quiz>>.failure(ServerFailure('unavailable'));
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      await expectLater(
        container.read(quizControllerProvider.future),
        throwsA(isA<Failure>()),
      );
    });
  });
}
