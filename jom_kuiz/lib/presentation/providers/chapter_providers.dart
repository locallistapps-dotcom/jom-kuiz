import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../data/datasources/chapter_remote_data_source.dart';
import '../../data/repositories/chapter_repository_impl.dart';
import '../../data/services/chapter_service.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/repositories/chapter_repository.dart';

/// Wires the Chapter feature's dependency chain:
/// `Dio → ChapterRemoteDataSource → ChapterRepository → ChapterService`.
///
/// UI-state providers (search query, sort order, subject/year filters) are
/// declared here so the controller and screen always read from the same source.

final Provider<ChapterRemoteDataSource> chapterRemoteDataSourceProvider =
    Provider<ChapterRemoteDataSource>(
  (Ref ref) => ChapterRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<ChapterRepository> chapterRepositoryProvider =
    Provider<ChapterRepository>(
  (Ref ref) =>
      ChapterRepositoryImpl(ref.watch(chapterRemoteDataSourceProvider)),
);

final Provider<ChapterService> chapterServiceProvider =
    Provider<ChapterService>(
  (Ref ref) =>
      ChapterService(repository: ref.watch(chapterRepositoryProvider)),
);

// ── UI state ──────────────────────────────────────────────────────────────────

/// The text currently typed in the chapter search bar.
final StateProvider<String> chapterSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// The sort order currently selected in the Chapter screen.
final StateProvider<ChapterSortOrder> chapterSortOrderProvider =
    StateProvider<ChapterSortOrder>(
  (Ref ref) => ChapterSortOrder.displayOrderAsc,
);

/// Optional Subject ID filter. Set before navigating to ChapterScreen to
/// pre-scope the list to a specific subject. Empty string = no filter (all).
final StateProvider<String> chapterSubjectFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Optional Year ID filter. Set before navigating to ChapterScreen to
/// pre-scope the list to a specific year. Empty string = no filter (all).
final StateProvider<String> chapterYearFilterProvider =
    StateProvider<String>((Ref ref) => '');

// ── Student browse ─────────────────────────────────────────────────────────────

/// Active chapters for a given subject ID — used by student chapter-browse screen.
/// Keyed on subjectId; auto-disposes when the screen is closed.
final AutoDisposeFutureProviderFamily<List<Chapter>, String>
    chaptersBySubjectProvider =
    FutureProvider.autoDispose.family<List<Chapter>, String>(
        (Ref ref, String subjectId) async {
  final Result<List<Chapter>> result =
      await ref.watch(chapterServiceProvider).getChapters(
            subjectId: subjectId,
            isActive: true,
            sortOrder: ChapterSortOrder.displayOrderAsc,
          );
  return result.when(
    success: (List<Chapter> list) => list,
    failure: (Failure f) => throw f,
  );
});
