import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/topic.dart';
import '../providers/topic_providers.dart';

// ── Provider declaration ──────────────────────────────────────────────────────

/// Loads and caches the topic list. Reacts to sort-order and all three
/// hierarchy filter providers (subject, year, chapter). Search filtering is
/// applied client-side via [filteredTopicsProvider] for instant response.
final AsyncNotifierProvider<TopicController, List<Topic>>
    topicControllerProvider =
    AsyncNotifierProvider<TopicController, List<Topic>>(TopicController.new);

/// Derived provider: applies client-side search query and sort order to the
/// full list cached by [topicControllerProvider].
///
/// Returns an empty list while loading or on error — the screen handles those
/// states by watching [topicControllerProvider] directly.
final Provider<List<Topic>> filteredTopicsProvider =
    Provider<List<Topic>>((Ref ref) {
  final AsyncValue<List<Topic>> async = ref.watch(topicControllerProvider);
  final String query =
      ref.watch(topicSearchQueryProvider).trim().toLowerCase();
  final TopicSortOrder sort = ref.watch(topicSortOrderProvider);

  final List<Topic> all = async.valueOrNull ?? <Topic>[];

  final List<Topic> filtered = query.isEmpty
      ? all
      : all
          .where(
            (Topic t) => t.topicName.toLowerCase().contains(query),
          )
          .toList();

  filtered.sort((Topic a, Topic b) {
    switch (sort) {
      case TopicSortOrder.displayOrderAsc:
        return a.displayOrder.compareTo(b.displayOrder);
      case TopicSortOrder.nameAsc:
        return a.topicName.toLowerCase().compareTo(
              b.topicName.toLowerCase(),
            );
      case TopicSortOrder.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
    }
  });

  return filtered;
});

// ── Controller ────────────────────────────────────────────────────────────────

class TopicController extends AsyncNotifier<List<Topic>> {
  @override
  Future<List<Topic>> build() async {
    final TopicSortOrder sort = ref.watch(topicSortOrderProvider);
    final String chapterId = ref.watch(topicChapterFilterProvider);
    final String subjectId = ref.watch(topicSubjectFilterProvider);
    final String yearId = ref.watch(topicYearFilterProvider);

    final Result<List<Topic>> result =
        await ref.watch(topicServiceProvider).getTopics(
              chapterId: chapterId.isEmpty ? null : chapterId,
              subjectId: subjectId.isEmpty ? null : subjectId,
              yearId: yearId.isEmpty ? null : yearId,
              sortOrder: sort,
            );

    return result.when(
      success: (List<Topic> list) => list,
      failure: (Failure failure) => throw failure,
    );
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncValue<List<Topic>>.loading();
    state = await AsyncValue.guard<List<Topic>>(() async {
      final TopicSortOrder sort = ref.read(topicSortOrderProvider);
      final String chapterId = ref.read(topicChapterFilterProvider);
      final String subjectId = ref.read(topicSubjectFilterProvider);
      final String yearId = ref.read(topicYearFilterProvider);

      final Result<List<Topic>> result =
          await ref.read(topicServiceProvider).getTopics(
                chapterId: chapterId.isEmpty ? null : chapterId,
                subjectId: subjectId.isEmpty ? null : subjectId,
                yearId: yearId.isEmpty ? null : yearId,
                sortOrder: sort,
              );
      return result.when(
        success: (List<Topic> list) => list,
        failure: (Failure f) => throw f,
      );
    });
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Topic>> createTopic({
    required String chapterId,
    required String topicName,
    String? description,
    required int displayOrder,
  }) async {
    final Result<Topic> result =
        await ref.read(topicServiceProvider).createTopic(
              chapterId: chapterId,
              topicName: topicName,
              description: description,
              displayOrder: displayOrder,
            );

    result.when(
      success: (Topic created) {
        final List<Topic> current =
            List<Topic>.from(state.valueOrNull ?? <Topic>[])..add(created);
        state = AsyncValue<List<Topic>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Topic>> updateTopic({
    required String topicId,
    required String chapterId,
    required String topicName,
    String? description,
    required int displayOrder,
    required bool isActive,
  }) async {
    final Result<Topic> result =
        await ref.read(topicServiceProvider).updateTopic(
              topicId: topicId,
              chapterId: chapterId,
              topicName: topicName,
              description: description,
              displayOrder: displayOrder,
              isActive: isActive,
            );

    result.when(
      success: (Topic updated) {
        final List<Topic> current =
            (state.valueOrNull ?? <Topic>[]).map((Topic t) {
          return t.topicId == updated.topicId ? updated : t;
        }).toList();
        state = AsyncValue<List<Topic>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteTopic({required String topicId}) async {
    final Result<void> result =
        await ref.read(topicServiceProvider).deleteTopic(topicId: topicId);

    result.when(
      success: (_) {
        final List<Topic> current = (state.valueOrNull ?? <Topic>[])
            .where((Topic t) => t.topicId != topicId)
            .toList();
        state = AsyncValue<List<Topic>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Topic>> toggleActive({
    required String topicId,
    required bool isActive,
  }) async {
    final Result<Topic> result =
        await ref.read(topicServiceProvider).toggleActive(
              topicId: topicId,
              isActive: isActive,
            );

    result.when(
      success: (Topic updated) {
        final List<Topic> current =
            (state.valueOrNull ?? <Topic>[]).map((Topic t) {
          return t.topicId == updated.topicId ? updated : t;
        }).toList();
        state = AsyncValue<List<Topic>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }
}
