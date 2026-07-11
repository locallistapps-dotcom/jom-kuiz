import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../data/datasources/topic_remote_data_source.dart';
import '../../data/repositories/topic_repository_impl.dart';
import '../../data/services/topic_service.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/topic_repository.dart';

/// Wires the Topic feature's dependency chain:
/// `Dio → TopicRemoteDataSource → TopicRepository → TopicService`.
///
/// UI-state providers (search query, sort order, hierarchy filters) are
/// declared here. The three filter providers form a cascade:
///
///   [topicSubjectFilterProvider] ──┐
///                                  ├─→ server-side JOIN filter
///   [topicYearFilterProvider]   ──┘
///
///   [topicChapterFilterProvider] ──→ direct chapter_id filter
///
/// When Subject or Year changes the screen clears [topicChapterFilterProvider]
/// so stale chapter selections are never sent to the server.

final Provider<TopicRemoteDataSource> topicRemoteDataSourceProvider =
    Provider<TopicRemoteDataSource>(
  (Ref ref) => TopicRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<TopicRepository> topicRepositoryProvider =
    Provider<TopicRepository>(
  (Ref ref) => TopicRepositoryImpl(ref.watch(topicRemoteDataSourceProvider)),
);

final Provider<TopicService> topicServiceProvider = Provider<TopicService>(
  (Ref ref) =>
      TopicService(repository: ref.watch(topicRepositoryProvider)),
);

// ── UI state ──────────────────────────────────────────────────────────────────

/// Text currently typed in the topic search bar.
final StateProvider<String> topicSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Sort order selected in the Topic screen.
final StateProvider<TopicSortOrder> topicSortOrderProvider =
    StateProvider<TopicSortOrder>(
  (Ref ref) => TopicSortOrder.displayOrderAsc,
);

/// Subject UUID filter — narrowing server-side via PostgREST JOIN.
/// Changing this should clear [topicChapterFilterProvider] (done in screen).
final StateProvider<String> topicSubjectFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Year UUID filter — narrowing server-side via PostgREST JOIN.
/// Changing this should clear [topicChapterFilterProvider] (done in screen).
final StateProvider<String> topicYearFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Chapter UUID filter — direct FK filter on topics.chapter_id.
/// Represents the narrowest, most specific filter scope.
final StateProvider<String> topicChapterFilterProvider =
    StateProvider<String>((Ref ref) => '');

// ── Student browse ─────────────────────────────────────────────────────────────

/// Active topics for a given chapter ID — used by student topic-browse screen.
/// Keyed on chapterId; auto-disposes when the screen is closed.
final AutoDisposeFutureProviderFamily<List<Topic>, String>
    topicsByChapterProvider =
    FutureProvider.autoDispose.family<List<Topic>, String>(
        (Ref ref, String chapterId) async {
  final Result<List<Topic>> result =
      await ref.watch(topicServiceProvider).getTopics(
            chapterId: chapterId,
            isActive: true,
            sortOrder: TopicSortOrder.displayOrderAsc,
          );
  return result.when(
    success: (List<Topic> list) => list,
    failure: (Failure f) => throw f,
  );
});
