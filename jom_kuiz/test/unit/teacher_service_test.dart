import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/data/services/teacher_service.dart';
import 'package:jom_kuiz/domain/entities/teacher_dashboard.dart';
import 'package:jom_kuiz/domain/repositories/teacher_repository.dart';

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
        ),
      ],
      recentActivities: <RecentActivity>[],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeTeacherRepository repository;
  late TeacherService service;

  setUp(() {
    repository = _FakeTeacherRepository();
    service = TeacherService(repository: repository);
  });

  group('TeacherService.getDashboard', () {
    test('returns dashboard on success', () async {
      final TeacherDashboard expected = _dashboard();
      repository.getDashboardResult = Result<TeacherDashboard>.success(expected);

      final Result<TeacherDashboard> result =
          await service.getDashboard(teacherId: 't1');

      result.when(
        success: (TeacherDashboard d) => expect(d, expected),
        failure: (_) => fail('Expected success'),
      );
    });

    test('returns ValidationFailure for empty teacherId', () async {
      final Result<TeacherDashboard> result =
          await service.getDashboard(teacherId: '');

      result.when(
        success: (_) => fail('Expected failure'),
        failure: (Failure f) {
          expect(f, isA<ValidationFailure>());
          expect(f.code, 'TEACHER-002');
        },
      );
    });

    test('returns ValidationFailure for whitespace-only teacherId', () async {
      final Result<TeacherDashboard> result =
          await service.getDashboard(teacherId: '   ');

      result.when(
        success: (_) => fail('Expected failure'),
        failure: (Failure f) => expect(f, isA<ValidationFailure>()),
      );
    });

    test('propagates repository failure', () async {
      repository.getDashboardResult = const Result<TeacherDashboard>.failure(
        ServerFailure('Server error', 'TEACHER-002'),
      );

      final Result<TeacherDashboard> result =
          await service.getDashboard(teacherId: 't1');

      result.when(
        success: (_) => fail('Expected failure'),
        failure: (Failure f) => expect(f, isA<ServerFailure>()),
      );
    });

    test('totalStudents is sum of assignedClasses studentCount', () async {
      final TeacherDashboard d = _dashboard();
      expect(d.totalStudents, 32);
    });

    test('totalStudents is 0 for empty class list', () {
      const TeacherDashboard empty = TeacherDashboard(
        profile: TeacherProfile(
          teacherId: 't2',
          fullName: 'Cikgu Ali',
          username: 'ali',
          email: 'ali@school.edu',
          subject: 'Science',
        ),
        school: SchoolInfo(schoolName: 'SK Bangsar'),
        assignedClasses: <TeacherClass>[],
        todaySchedule: <ScheduleItem>[],
        recentActivities: <RecentActivity>[],
      );
      expect(empty.totalStudents, 0);
    });
  });
}
