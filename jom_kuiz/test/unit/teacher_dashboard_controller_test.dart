import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/di/providers.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/teacher_dashboard.dart';
import 'package:jom_kuiz/domain/repositories/teacher_repository.dart';
import 'package:jom_kuiz/presentation/controllers/teacher_dashboard_controller.dart';
import 'package:jom_kuiz/presentation/providers/teacher_providers.dart';

import '../helpers/fake_token_storage.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeTeacherRepository implements TeacherRepository {
  Result<TeacherDashboard>? getDashboardResult;

  @override
  Future<Result<TeacherDashboard>> getDashboard(
          {required String teacherId}) async =>
      getDashboardResult!;
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

TeacherDashboard _dashboard() => const TeacherDashboard(
      profile: TeacherProfile(
        teacherId: 't1',
        fullName: 'Puan Siti',
        username: 'siti_edu',
        email: 'siti@school.edu',
        subject: 'Mathematics',
        employeeId: 'EMP-001',
      ),
      school: SchoolInfo(schoolName: 'SK Damansara'),
      assignedClasses: <TeacherClass>[
        TeacherClass(
          classId: 'c1',
          name: '4 Amanah',
          subject: 'Mathematics',
          studentCount: 32,
          gradeLevel: 'Year 4',
        ),
      ],
      todaySchedule: <ScheduleItem>[
        ScheduleItem(
          time: '08:00',
          subject: 'Mathematics',
          className: '4 Amanah',
          room: 'Bilik 101',
        ),
      ],
      recentActivities: <RecentActivity>[],
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _buildContainer(
  _FakeTeacherRepository repo, {
  String teacherId = 't1',
}) {
  return ProviderContainer(
    overrides: <Override>[
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      teacherRepositoryProvider.overrideWithValue(repo),
      currentTeacherIdProvider.overrideWith((Ref ref) => teacherId),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeTeacherRepository repository;

  setUp(() => repository = _FakeTeacherRepository());

  group('TeacherDashboardController.build', () {
    test('loads dashboard successfully', () async {
      repository.getDashboardResult =
          Result<TeacherDashboard>.success(_dashboard());
      final ProviderContainer container = _buildContainer(repository);
      addTearDown(container.dispose);

      final TeacherDashboard? result =
          await container.read(teacherDashboardControllerProvider.future);

      expect(result, isNotNull);
      expect(result!.profile.fullName, 'Puan Siti');
      expect(result.totalStudents, 32);
    });

    test('returns null when teacherId is empty', () async {
      final ProviderContainer container =
          _buildContainer(repository, teacherId: '');
      addTearDown(container.dispose);

      final TeacherDashboard? result =
          await container.read(teacherDashboardControllerProvider.future);

      expect(result, isNull);
    });

    test('transitions to AsyncError on repository failure', () async {
      repository.getDashboardResult = const Result<TeacherDashboard>.failure(
        ServerFailure('Server error'),
      );
      final ProviderContainer container = _buildContainer(repository);
      addTearDown(container.dispose);

      await expectLater(
        container.read(teacherDashboardControllerProvider.future),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('TeacherDashboardController.refresh', () {
    test('refresh reloads dashboard successfully', () async {
      repository.getDashboardResult =
          Result<TeacherDashboard>.success(_dashboard());
      final ProviderContainer container = _buildContainer(repository);
      addTearDown(container.dispose);

      // Await initial build.
      await container.read(teacherDashboardControllerProvider.future);

      // Trigger refresh.
      await container
          .read(teacherDashboardControllerProvider.notifier)
          .refresh();

      final AsyncValue<TeacherDashboard?> state =
          container.read(teacherDashboardControllerProvider);
      expect(state, isA<AsyncData<TeacherDashboard?>>());
      expect(state.value?.profile.email, 'siti@school.edu');
    });

    test('refresh with empty teacherId yields null', () async {
      final ProviderContainer container =
          _buildContainer(repository, teacherId: '');
      addTearDown(container.dispose);

      await container.read(teacherDashboardControllerProvider.future);
      await container
          .read(teacherDashboardControllerProvider.notifier)
          .refresh();

      final AsyncValue<TeacherDashboard?> state =
          container.read(teacherDashboardControllerProvider);
      expect(state.value, isNull);
    });
  });

  group('TeacherDashboard entity', () {
    test('totalStudents sums all class studentCounts', () {
      const TeacherDashboard d = TeacherDashboard(
        profile: TeacherProfile(
          teacherId: 't1',
          fullName: 'Test',
          username: 'test',
          email: 'test@edu.com',
          subject: 'Maths',
        ),
        school: SchoolInfo(schoolName: 'SK Test'),
        assignedClasses: <TeacherClass>[
          TeacherClass(
              classId: 'c1',
              name: 'A',
              subject: 'Maths',
              studentCount: 20),
          TeacherClass(
              classId: 'c2',
              name: 'B',
              subject: 'Maths',
              studentCount: 15),
        ],
        todaySchedule: <ScheduleItem>[],
        recentActivities: <RecentActivity>[],
      );
      expect(d.totalStudents, 35);
    });
  });
}
