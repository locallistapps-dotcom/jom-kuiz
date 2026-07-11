import '../../core/utils/result.dart';
import '../entities/topic.dart';

/// Abstract contract for Topic CRUD operations.
///
/// The implementation is backed by Supabase REST (PostgREST) via the shared
/// Dio instance. All methods return [Result] — no exceptions escape this layer.
///
/// Topics are always scoped to a Chapter. The optional [subjectId] and
/// [yearId] parameters on [getTopics] are server-side convenience filters that
/// let callers scope results without knowing chapter IDs up front.
abstract interface class TopicRepository {
  /// Returns topics filtered by any combination of [chapterId], [subjectId],
  /// [yearId], and [search] text, sorted by [sortOrder].
  ///
  /// Passing all three FK filters produces the narrowest result set.
  /// Passing none returns all topics (admin view).
  Future<Result<List<Topic>>> getTopics({
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    TopicSortOrder sortOrder,
    bool? isActive,
  });

  /// Returns a single topic by primary key.
  Future<Result<Topic>> getTopicById({required String topicId});

  /// Creates a new topic linked to a Chapter.
  Future<Result<Topic>> createTopic({
    required String chapterId,
    required String topicName,
    String? description,
    int displayOrder,
  });

  /// Updates all mutable fields of an existing topic.
  Future<Result<Topic>> updateTopic({
    required String topicId,
    required String chapterId,
    required String topicName,
    String? description,
    required int displayOrder,
    required bool isActive,
  });

  /// Hard-deletes a topic. Returns [Result.success] with `null` on success.
  Future<Result<void>> deleteTopic({required String topicId});

  /// Flips [Topic.isActive] for the given [topicId].
  Future<Result<Topic>> toggleActive({
    required String topicId,
    required bool isActive,
  });
}
