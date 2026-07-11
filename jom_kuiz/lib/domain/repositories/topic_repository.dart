import '../../core/utils/result.dart';
import '../entities/topic.dart';

/// Abstract contract for topic catalogue operations.
abstract interface class TopicRepository {
  /// Returns all topics within a [chapterId], ordered by [Topic.order].
  Future<Result<List<Topic>>> getTopics({required String chapterId});

  /// Returns a single topic by [topicId].
  Future<Result<Topic>> getTopicById({required String topicId});
}
