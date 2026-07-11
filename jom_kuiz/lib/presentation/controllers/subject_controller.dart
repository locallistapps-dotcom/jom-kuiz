import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/subject.dart';
import '../providers/subject_providers.dart';

// ── Provider declaration ──────────────────────────────────────────────────────

/// Loads and caches the full subject list. Reacts to sort-order changes by
/// re-fetching. Search filtering is applied client-side via
/// [filteredSubjectsProvider] so the list updates instantly as the user types.
final AsyncNotifierProvider<SubjectController, List<Subject>>
    subjectControllerProvider =
    AsyncNotifierProvider<SubjectController, List<Subject>>(
        SubjectController.new);

/// Derived provider that applies the current search query and sort order to
/// the full list held by [subjectControllerProvider].
///
/// Returns an empty list while loading or on error — the screen handles those
/// states separately by watching [subjectControllerProvider] directly.
final Provider<List<Subject>> filteredSubjectsProvider =
    Provider<List<Subject>>((Ref ref) {
  final AsyncValue<List<Subject>> async =
      ref.watch(subjectControllerProvider);
  final String query =
      ref.watch(subjectSearchQueryProvider).trim().toLowerCase();
  final SubjectSortOrder sort = ref.watch(subjectSortOrderProvider);

  final List<Subject> all = async.valueOrNull ?? <Subject>[];

  // Apply search filter
  final List<Subject> filtered = query.isEmpty
      ? all
      : all
          .where((Subject s) =>
              s.subjectName.toLowerCase().contains(query) ||
              (s.description?.toLowerCase().contains(query) ?? false))
          .toList();

  // Apply sort (already sorted server-side on initial fetch, but kept here
  // so client-side mutations stay correctly ordered without a round-trip).
  filtered.sort((Subject a, Subject b) {
    switch (sort) {
      case SubjectSortOrder.nameAsc:
        return a.subjectName
            .toLowerCase()
            .compareTo(b.subjectName.toLowerCase());
      case SubjectSortOrder.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
    }
  });

  return filtered;
});

// ── Controller ────────────────────────────────────────────────────────────────

class SubjectController extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    final SubjectSortOrder sort = ref.watch(subjectSortOrderProvider);
    final Result<List<Subject>> result =
        await ref.watch(subjectServiceProvider).getSubjects(sortOrder: sort);
    return result.when(
      success: (List<Subject> list) => list,
      failure: (Failure failure) => throw failure,
    );
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncValue<List<Subject>>.loading();
    state = await AsyncValue.guard<List<Subject>>(() async {
      final SubjectSortOrder sort = ref.read(subjectSortOrderProvider);
      final Result<List<Subject>> result =
          await ref.read(subjectServiceProvider).getSubjects(sortOrder: sort);
      return result.when(
        success: (List<Subject> list) => list,
        failure: (Failure f) => throw f,
      );
    });
  }

  // ── Mutations (return Result so screens can show inline errors) ────────────

  Future<Result<Subject>> createSubject({
    required String subjectName,
    String? description,
    String? icon,
    required int displayOrder,
  }) async {
    final Result<Subject> result =
        await ref.read(subjectServiceProvider).createSubject(
              subjectName: subjectName,
              description: description,
              icon: icon,
              displayOrder: displayOrder,
            );

    result.when(
      success: (Subject created) {
        final List<Subject> current =
            List<Subject>.from(state.valueOrNull ?? <Subject>[])
              ..add(created);
        state = AsyncValue<List<Subject>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Subject>> updateSubject({
    required String subjectId,
    required String subjectName,
    String? description,
    String? icon,
    required int displayOrder,
    required bool isActive,
  }) async {
    final Result<Subject> result =
        await ref.read(subjectServiceProvider).updateSubject(
              subjectId: subjectId,
              subjectName: subjectName,
              description: description,
              icon: icon,
              displayOrder: displayOrder,
              isActive: isActive,
            );

    result.when(
      success: (Subject updated) {
        final List<Subject> current =
            (state.valueOrNull ?? <Subject>[]).map((Subject s) {
          return s.subjectId == updated.subjectId ? updated : s;
        }).toList();
        state = AsyncValue<List<Subject>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteSubject({required String subjectId}) async {
    final Result<void> result =
        await ref.read(subjectServiceProvider).deleteSubject(
              subjectId: subjectId,
            );

    result.when(
      success: (_) {
        final List<Subject> current = (state.valueOrNull ?? <Subject>[])
            .where((Subject s) => s.subjectId != subjectId)
            .toList();
        state = AsyncValue<List<Subject>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Subject>> toggleActive({
    required String subjectId,
    required bool isActive,
  }) async {
    final Result<Subject> result =
        await ref.read(subjectServiceProvider).toggleActive(
              subjectId: subjectId,
              isActive: isActive,
            );

    result.when(
      success: (Subject updated) {
        final List<Subject> current =
            (state.valueOrNull ?? <Subject>[]).map((Subject s) {
          return s.subjectId == updated.subjectId ? updated : s;
        }).toList();
        state = AsyncValue<List<Subject>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }
}
