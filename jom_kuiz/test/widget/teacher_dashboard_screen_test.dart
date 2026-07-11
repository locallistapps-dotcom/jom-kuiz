import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/di/providers.dart';
import 'package:jom_kuiz/core/error/failure.dart';
import 'package:jom_kuiz/core/utils/result.dart';
import 'package:jom_kuiz/domain/entities/teacher_dashboard.dart';
import 'package:jom_kuiz/domain/repositories/teacher_repository.dart';
import 'package:jom_kuiz/presentation/controllers/teacher_dashboard_controller.dart';
import 'package:jom_kuiz/presentation/providers/teacher_providers.dart';
import 'package:jom_kuiz/presentation/screens/teacher/teacher_dashboard_screen.dart';

import '../helpers/fake_token_storage.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeTeacherRepository implements TeacherRepository {
  final Result<TeacherDashboard> result;
  const _FakeTeacherRepository(this.result);

  @override
  Future<Result<TeacherDashboard>> getDashboard(
          {required String teacherId}) async =>
      result;
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

TeacherDashboard _dashboard() => TeacherDashboard(
      profile: const TeacherProfile(
        teacherId: 't1',
        fullName: 'Puan Siti Aminah',
        username: 'siti_edu',
        email: 'siti@school.edu',
        subject: 'Mathematics',
        employeeId: 'EMP-001',
      ),
      school: const SchoolInfo(
        schoolName: 'SK Damansara',
        schoolType: 'Sekolah Kebangsaan',
        academicYear: '2025/2026',
      ),
      assignedClasses: const <TeacherClass>[
        TeacherClass(
          classId: 'c1',
          name: '4 Amanah',
          subject: 'Mathematics',
          studentCount: 32,
          gradeLevel: 'Year 4',
        ),
        TeacherClass(
          classId: 'c2',
          name: '4 Bestari',
          subject: 'Mathematics',
          studentCount: 28,
          gradeLevel: 'Year 4',
        ),
      ],
      todaySchedule: const <ScheduleItem>[
        ScheduleItem(
          time: '08:00',
          subject: 'Mathematics',
          className: '4 Amanah',
          room: 'Bilik 101',
        ),
      ],
      recentActivities: <RecentActivity>[
        RecentActivity(
          type: ActivityType.homework,
          description: 'Assigned: Fractions worksheet',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    );

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildSubject({
  required TeacherDashboard? dashboardData,
  bool isError = false,
}) {
  return ProviderScope(
    overrides: <Override>[
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      teacherRepositoryProvider.overrideWithValue(
        isError
            ? _FakeTeacherRepository(
                const Result<TeacherDashboard>.failure(
                    ServerFailure('Server error')))
            : _FakeTeacherRepository(
                dashboardData != null
                    ? Result<TeacherDashboard>.success(dashboardData)
                    : const Result<TeacherDashboard>.failure(
                        ServerFailure('No data'))),
      ),
      currentTeacherIdProvider.overrideWith(
          (Ref ref) => dashboardData != null ? 't1' : ''),
    ],
    child: const MaterialApp(
      home: TeacherDashboardScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TeacherDashboardScreen', () {
    testWidgets('shows welcome card with teacher name', (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(dashboardData: _dashboard()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Puan Siti Aminah'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows school information', (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(dashboardData: _dashboard()));
      await tester.pumpAndSettle();

      expect(find.text('SK Damansara'), findsOneWidget);
      expect(find.text('2025/2026'), findsOneWidget);
    });

    testWidgets('shows assigned classes with student counts',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(dashboardData: _dashboard()));
      await tester.pumpAndSettle();

      expect(find.text('4 Amanah'), findsOneWidget);
      expect(find.text('4 Bestari'), findsOneWidget);
      // Total students badge: 32 + 28 = 60
      expect(find.textContaining('60'), findsAtLeastNWidgets(1));
    });

    testWidgets("shows today's schedule", (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(dashboardData: _dashboard()));
      await tester.pumpAndSettle();

      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Bilik 101'), findsNothing); // inside subtitle, check combined
      expect(find.textContaining('Bilik 101'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows quick action chips', (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(dashboardData: _dashboard()));
      await tester.pumpAndSettle();

      expect(find.text('My Classes'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Homework'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);
    });

    testWidgets('shows empty state when teacherId is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(dashboardData: null));
      await tester.pumpAndSettle();

      expect(find.textContaining('No teacher data'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(dashboardData: _dashboard()));
      // Do not settle — check the loading state.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
