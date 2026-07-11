import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/di/providers.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/achievement.dart';
import 'package:jom_kuiz/domain/entities/child_profile.dart';
import 'package:jom_kuiz/domain/entities/homework.dart';
import 'package:jom_kuiz/domain/entities/quiz.dart';
import 'package:jom_kuiz/domain/repositories/child_repository.dart';
import 'package:jom_kuiz/presentation/providers/child_providers.dart';
import 'package:jom_kuiz/presentation/screens/child/child_dashboard_screen.dart';

import '../helpers/fake_token_storage.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeChildRepository implements ChildRepository {
  final ChildProfile profile;

  _FakeChildRepository({required this.profile});

  @override
  Future<Result<ChildProfile>> getProfile({required String childId}) async =>
      Result<ChildProfile>.success(profile);

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
      throw UnimplementedError();

  @override
  Future<Result<ChildProfile>> updateAvatar({
    required String childId,
    required String localFilePath,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Homework>>> getHomework({required String childId}) async =>
      const Result<List<Homework>>.success(<Homework>[]);

  @override
  Future<Result<Homework>> getHomeworkDetail(
          {required String homeworkId}) async =>
      throw UnimplementedError();

  @override
  Future<Result<List<Quiz>>> getQuizList() async =>
      const Result<List<Quiz>>.success(<Quiz>[]);

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
// Helper
// ---------------------------------------------------------------------------

final DateTime _ts = DateTime(2026, 1, 1);

ChildProfile _profile({LinkedParent? linkedParent}) => ChildProfile(
      childId: 'c1',
      fullName: 'Ahmad',
      username: 'ahmad123',
      school: 'SK Bangsar',
      grade: 'Year 4',
      linkedParent: linkedParent,
      createdAt: _ts,
      updatedAt: _ts,
    );

Widget _buildScreen(ChildProfile profile) => ProviderScope(
      overrides: <Override>[
        // Prevent flutter_secure_storage MissingPluginException in tests.
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        childRepositoryProvider.overrideWithValue(
            _FakeChildRepository(profile: profile)),
        // Pre-seed the child ID so controllers load immediately.
        currentChildIdProvider.overrideWith((ref) => 'c1'),
      ],
      child: const MaterialApp(home: ChildDashboardScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('shows the welcome card with the child name',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_profile()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ahmad'), findsWidgets);
  });

  testWidgets('shows class information on the dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_profile()));
    await tester.pumpAndSettle();

    expect(find.text('SK Bangsar'), findsOneWidget);
    expect(find.text('Year 4'), findsOneWidget);
  });

  testWidgets('shows linked parent card when parent is linked',
      (WidgetTester tester) async {
    final LinkedParent parent = LinkedParent(
      parentId: 'p1',
      fullName: 'Ali Bin Abu',
      email: 'ali@example.com',
      linkStatus: LinkStatus.linked,
      relationship: 'Father',
    );

    await tester.pumpWidget(_buildScreen(_profile(linkedParent: parent)));
    await tester.pumpAndSettle();

    expect(find.text('Ali Bin Abu'), findsOneWidget);
    expect(find.text('linked'), findsOneWidget);
  });

  testWidgets('shows "No parent linked" when no parent is associated',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_profile()));
    await tester.pumpAndSettle();

    expect(find.text('No parent linked'), findsOneWidget);
  });

  testWidgets('quick action chips are visible', (WidgetTester tester) async {
    await tester.pumpWidget(_buildScreen(_profile()));
    await tester.pumpAndSettle();

    expect(find.text('Homework'), findsWidgets);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
  });
}
