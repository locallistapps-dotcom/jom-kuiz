import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/year.dart';
import '../providers/year_providers.dart';

// ── Provider declaration ──────────────────────────────────────────────────────

/// Loads and caches the full year list. Reacts to sort-order changes by
/// re-fetching. Search filtering is applied client-side via
/// [filteredYearsProvider] so the list updates instantly as the user types.
final AsyncNotifierProvider<YearController, List<Year>>
    yearControllerProvider =
    AsyncNotifierProvider<YearController, List<Year>>(YearController.new);

/// Derived provider that applies the current search query and sort order to
/// the full list held by [yearControllerProvider].
///
/// Returns an empty list while loading or on error — the screen handles those
/// states separately by watching [yearControllerProvider] directly.
final Provider<List<Year>> filteredYearsProvider =
    Provider<List<Year>>((Ref ref) {
  final AsyncValue<List<Year>> async = ref.watch(yearControllerProvider);
  final String query =
      ref.watch(yearSearchQueryProvider).trim().toLowerCase();
  final YearSortOrder sort = ref.watch(yearSortOrderProvider);

  final List<Year> all = async.valueOrNull ?? <Year>[];

  // Apply search filter
  final List<Year> filtered = query.isEmpty
      ? all
      : all
          .where((Year y) => y.yearName.toLowerCase().contains(query))
          .toList();

  // Apply sort (mirrors server-side ordering; keeps mutations sorted without
  // a network round-trip).
  filtered.sort((Year a, Year b) {
    switch (sort) {
      case YearSortOrder.nameAsc:
        return a.yearName.toLowerCase().compareTo(b.yearName.toLowerCase());
      case YearSortOrder.displayOrderAsc:
        return a.displayOrder.compareTo(b.displayOrder);
      case YearSortOrder.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
    }
  });

  return filtered;
});

// ── Controller ────────────────────────────────────────────────────────────────

class YearController extends AsyncNotifier<List<Year>> {
  @override
  Future<List<Year>> build() async {
    final YearSortOrder sort = ref.watch(yearSortOrderProvider);
    final Result<List<Year>> result =
        await ref.watch(yearServiceProvider).getYears(sortOrder: sort);
    return result.when(
      success: (List<Year> list) => list,
      failure: (Failure failure) => throw failure,
    );
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncValue<List<Year>>.loading();
    state = await AsyncValue.guard<List<Year>>(() async {
      final YearSortOrder sort = ref.read(yearSortOrderProvider);
      final Result<List<Year>> result =
          await ref.read(yearServiceProvider).getYears(sortOrder: sort);
      return result.when(
        success: (List<Year> list) => list,
        failure: (Failure f) => throw f,
      );
    });
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Year>> createYear({
    required String yearName,
    required int displayOrder,
  }) async {
    final Result<Year> result =
        await ref.read(yearServiceProvider).createYear(
              yearName: yearName,
              displayOrder: displayOrder,
            );

    result.when(
      success: (Year created) {
        final List<Year> current =
            List<Year>.from(state.valueOrNull ?? <Year>[])..add(created);
        state = AsyncValue<List<Year>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Year>> updateYear({
    required String yearId,
    required String yearName,
    required int displayOrder,
    required bool isActive,
  }) async {
    final Result<Year> result =
        await ref.read(yearServiceProvider).updateYear(
              yearId: yearId,
              yearName: yearName,
              displayOrder: displayOrder,
              isActive: isActive,
            );

    result.when(
      success: (Year updated) {
        final List<Year> current =
            (state.valueOrNull ?? <Year>[]).map((Year y) {
          return y.yearId == updated.yearId ? updated : y;
        }).toList();
        state = AsyncValue<List<Year>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteYear({required String yearId}) async {
    final Result<void> result =
        await ref.read(yearServiceProvider).deleteYear(yearId: yearId);

    result.when(
      success: (_) {
        final List<Year> current = (state.valueOrNull ?? <Year>[])
            .where((Year y) => y.yearId != yearId)
            .toList();
        state = AsyncValue<List<Year>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Year>> toggleActive({
    required String yearId,
    required bool isActive,
  }) async {
    final Result<Year> result =
        await ref.read(yearServiceProvider).toggleActive(
              yearId: yearId,
              isActive: isActive,
            );

    result.when(
      success: (Year updated) {
        final List<Year> current =
            (state.valueOrNull ?? <Year>[]).map((Year y) {
          return y.yearId == updated.yearId ? updated : y;
        }).toList();
        state = AsyncValue<List<Year>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }
}
