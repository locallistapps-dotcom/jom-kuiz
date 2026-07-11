import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/teacher_dashboard.dart';
import '../providers/teacher_providers.dart';

/// Manages the Teacher Dashboard's async state.
///
/// Reacts automatically when [currentTeacherIdProvider] changes (e.g. on
/// first login or when the teacher ID is injected from the session).
/// Returns `null` without a network call when the ID is empty so tests and
/// placeholder navigation stay safe.
final AsyncNotifierProvider<TeacherDashboardController, TeacherDashboard?>
    teacherDashboardControllerProvider =
    AsyncNotifierProvider<TeacherDashboardController, TeacherDashboard?>(
        TeacherDashboardController.new);

class TeacherDashboardController extends AsyncNotifier<TeacherDashboard?> {
  @override
  Future<TeacherDashboard?> build() async {
    final String teacherId = ref.watch(currentTeacherIdProvider);
    if (teacherId.isEmpty) return null;

    final Result<TeacherDashboard> result = await ref
        .watch(teacherServiceProvider)
        .getDashboard(teacherId: teacherId);

    return result.when(
      success: (TeacherDashboard dashboard) => dashboard,
      failure: (Failure failure) => throw failure,
    );
  }

  /// Forces a reload of the dashboard from the network.
  Future<void> refresh() async {
    state = const AsyncValue<TeacherDashboard?>.loading();
    state = await AsyncValue.guard<TeacherDashboard?>(() async {
      final String teacherId = ref.read(currentTeacherIdProvider);
      if (teacherId.isEmpty) return null;
      final Result<TeacherDashboard> result = await ref
          .read(teacherServiceProvider)
          .getDashboard(teacherId: teacherId);
      return result.when(
        success: (TeacherDashboard d) => d,
        failure: (Failure f) => throw f,
      );
    });
  }
}
