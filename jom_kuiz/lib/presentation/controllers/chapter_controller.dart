import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/chapter.dart';
import '../providers/chapter_providers.dart';

// ── Provider declaration ──────────────────────────────────────────────────────

/// Loads and caches the chapter list. Reacts to sort-order and subject/year
/// filter changes by re-fetching from the server. Search filtering is applied
/// client-side via [filteredChaptersProvider] so the list updates instantly.
final AsyncNotifierProvider<ChapterController, List<Chapter>>
    chapterControllerProvider =
    AsyncNotifierProvider<ChapterController, List<Chapter>>(
  ChapterController.new,
);

/// Derived provider that applies the current search query and sort order to
/// the full list held by [chapterControllerProvider].
///
/// Returns an empty list while loading or on error — the screen handles those
/// states separately by watching [chapterControllerProvider] directly.
final Provider<List<Chapter>> filteredChaptersProvider =
    Provider<List<Chapter>>((Ref ref) {
  final AsyncValue<List<Chapter>> async =
      ref.watch(chapterControllerProvider);
  final String query =
      ref.watch(chapterSearchQueryProvider).trim().toLowerCase();
  final ChapterSortOrder sort = ref.watch(chapterSortOrderProvider);

  final List<Chapter> all = async.valueOrNull ?? <Chapter>[];

  // Apply search filter
  final List<Chapter> filtered = query.isEmpty
      ? all
      : all
          .where(
            (Chapter c) => c.chapterName.toLowerCase().contains(query),
          )
          .toList();

  // Apply sort (mirrors server-side ordering; keeps list sorted after
  // client-side mutations without a network round-trip).
  filtered.sort((Chapter a, Chapter b) {
    switch (sort) {
      case ChapterSortOrder.displayOrderAsc:
        return a.displayOrder.compareTo(b.displayOrder);
      case ChapterSortOrder.nameAsc:
        return a.chapterName.toLowerCase().compareTo(
              b.chapterName.toLowerCase(),
            );
      case ChapterSortOrder.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
    }
  });

  return filtered;
});

// ── Controller ────────────────────────────────────────────────────────────────

class ChapterController extends AsyncNotifier<List<Chapter>> {
  @override
  Future<List<Chapter>> build() async {
    final ChapterSortOrder sort = ref.watch(chapterSortOrderProvider);
    final String subjectId = ref.watch(chapterSubjectFilterProvider);
    final String yearId = ref.watch(chapterYearFilterProvider);

    final Result<List<Chapter>> result =
        await ref.watch(chapterServiceProvider).getChapters(
              subjectId: subjectId.isEmpty ? null : subjectId,
              yearId: yearId.isEmpty ? null : yearId,
              sortOrder: sort,
            );
    return result.when(
      success: (List<Chapter> list) => list,
      failure: (Failure failure) => throw failure,
    );
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncValue<List<Chapter>>.loading();
    state = await AsyncValue.guard<List<Chapter>>(() async {
      final ChapterSortOrder sort = ref.read(chapterSortOrderProvider);
      final String subjectId = ref.read(chapterSubjectFilterProvider);
      final String yearId = ref.read(chapterYearFilterProvider);

      final Result<List<Chapter>> result =
          await ref.read(chapterServiceProvider).getChapters(
                subjectId: subjectId.isEmpty ? null : subjectId,
                yearId: yearId.isEmpty ? null : yearId,
                sortOrder: sort,
              );
      return result.when(
        success: (List<Chapter> list) => list,
        failure: (Failure f) => throw f,
      );
    });
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Chapter>> createChapter({
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    required int displayOrder,
  }) async {
    final Result<Chapter> result =
        await ref.read(chapterServiceProvider).createChapter(
              subjectId: subjectId,
              yearId: yearId,
              chapterName: chapterName,
              description: description,
              displayOrder: displayOrder,
            );

    result.when(
      success: (Chapter created) {
        final List<Chapter> current =
            List<Chapter>.from(state.valueOrNull ?? <Chapter>[])
              ..add(created);
        state = AsyncValue<List<Chapter>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Chapter>> updateChapter({
    required String chapterId,
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    required int displayOrder,
    required bool isActive,
  }) async {
    final Result<Chapter> result =
        await ref.read(chapterServiceProvider).updateChapter(
              chapterId: chapterId,
              subjectId: subjectId,
              yearId: yearId,
              chapterName: chapterName,
              description: description,
              displayOrder: displayOrder,
              isActive: isActive,
            );

    result.when(
      success: (Chapter updated) {
        final List<Chapter> current =
            (state.valueOrNull ?? <Chapter>[]).map((Chapter c) {
          return c.chapterId == updated.chapterId ? updated : c;
        }).toList();
        state = AsyncValue<List<Chapter>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteChapter({required String chapterId}) async {
    final Result<void> result =
        await ref.read(chapterServiceProvider).deleteChapter(
              chapterId: chapterId,
            );

    result.when(
      success: (_) {
        final List<Chapter> current =
            (state.valueOrNull ?? <Chapter>[])
                .where((Chapter c) => c.chapterId != chapterId)
                .toList();
        state = AsyncValue<List<Chapter>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Chapter>> toggleActive({
    required String chapterId,
    required bool isActive,
  }) async {
    final Result<Chapter> result =
        await ref.read(chapterServiceProvider).toggleActive(
              chapterId: chapterId,
              isActive: isActive,
            );

    result.when(
      success: (Chapter updated) {
        final List<Chapter> current =
            (state.valueOrNull ?? <Chapter>[]).map((Chapter c) {
          return c.chapterId == updated.chapterId ? updated : c;
        }).toList();
        state = AsyncValue<List<Chapter>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }
}
