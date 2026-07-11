import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/homework.dart';
import '../providers/child_providers.dart';

/// Manages the homework list for the currently selected child.
///
/// Reacts automatically when [currentChildIdProvider] changes.
final AsyncNotifierProvider<HomeworkController, List<Homework>>
    homeworkControllerProvider =
    AsyncNotifierProvider<HomeworkController, List<Homework>>(
        HomeworkController.new);

class HomeworkController extends AsyncNotifier<List<Homework>> {
  @override
  Future<List<Homework>> build() async {
    final String childId = ref.watch(currentChildIdProvider);
    if (childId.isEmpty) return <Homework>[];
    final Result<List<Homework>> result =
        await ref.watch(childServiceProvider).getHomework(childId: childId);
    return result.when(
      success: (List<Homework> list) => list,
      failure: (Failure failure) => throw failure,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<Homework>>.loading();
    state = await AsyncValue.guard<List<Homework>>(() async {
      final String childId = ref.read(currentChildIdProvider);
      if (childId.isEmpty) return <Homework>[];
      final Result<List<Homework>> result =
          await ref.read(childServiceProvider).getHomework(childId: childId);
      return result.when(success: (l) => l, failure: (f) => throw f);
    });
  }

  /// Returns the pending + overdue homework sorted by due date ascending.
  List<Homework> get pending {
    final List<Homework>? list = state.valueOrNull;
    if (list == null) return <Homework>[];
    return list
        .where((Homework h) => !h.isCompleted)
        .toList()
      ..sort((Homework a, Homework b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Returns completed homework sorted by completion date descending.
  List<Homework> get completed {
    final List<Homework>? list = state.valueOrNull;
    if (list == null) return <Homework>[];
    return list
        .where((Homework h) => h.isCompleted)
        .toList()
      ..sort((Homework a, Homework b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return b.completedAt!.compareTo(a.completedAt!);
      });
  }
}
