import '../../core/error/failure.dart';
import '../../core/error/topic_error_codes.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/topic_repository.dart';

/// Orchestrates Topic business flows on top of [TopicRepository].
///
/// Handles input validation before delegating to the repository so the
/// controller layer never talks to the repository directly.
class TopicService {
  const TopicService({required TopicRepository repository})
      : _repository = repository;

  final TopicRepository _repository;

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Result<List<Topic>>> getTopics({
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    TopicSortOrder sortOrder = TopicSortOrder.displayOrderAsc,
    bool? isActive,
  }) {
    return _repository.getTopics(
      chapterId:
          (chapterId?.trim().isNotEmpty ?? false) ? chapterId!.trim() : null,
      subjectId:
          (subjectId?.trim().isNotEmpty ?? false) ? subjectId!.trim() : null,
      yearId: (yearId?.trim().isNotEmpty ?? false) ? yearId!.trim() : null,
      search: (search?.trim().isNotEmpty ?? false) ? search!.trim() : null,
      sortOrder: sortOrder,
      isActive: isActive,
    );
  }

  Future<Result<Topic>> getTopicById({required String topicId}) {
    if (topicId.trim().isEmpty) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Topic ID must not be empty',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    return _repository.getTopicById(topicId: topicId);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Topic>> createTopic({
    required String chapterId,
    required String topicName,
    String? description,
    int displayOrder = 0,
  }) {
    final String cid = chapterId.trim();
    final String name = topicName.trim();

    if (cid.isEmpty) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Chapter ID is required',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    if (name.isEmpty) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Topic name is required',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    if (name.length > 150) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Topic name must not exceed 150 characters',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }

    final String? desc =
        (description?.trim().isNotEmpty ?? false) ? description!.trim() : null;

    return _repository.createTopic(
      chapterId: cid,
      topicName: name,
      description: desc,
      displayOrder: displayOrder,
    );
  }

  Future<Result<Topic>> updateTopic({
    required String topicId,
    required String chapterId,
    required String topicName,
    String? description,
    required int displayOrder,
    required bool isActive,
  }) {
    final String id = topicId.trim();
    final String cid = chapterId.trim();
    final String name = topicName.trim();

    if (id.isEmpty) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Topic ID must not be empty',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    if (cid.isEmpty) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Chapter ID is required',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    if (name.isEmpty) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Topic name is required',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    if (name.length > 150) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Topic name must not exceed 150 characters',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }

    final String? desc =
        (description?.trim().isNotEmpty ?? false) ? description!.trim() : null;

    return _repository.updateTopic(
      topicId: id,
      chapterId: cid,
      topicName: name,
      description: desc,
      displayOrder: displayOrder,
      isActive: isActive,
    );
  }

  Future<Result<void>> deleteTopic({required String topicId}) {
    if (topicId.trim().isEmpty) {
      return Future<Result<void>>.value(
        const Result<void>.failure(
          ValidationFailure(
            'Topic ID must not be empty',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    return _repository.deleteTopic(topicId: topicId);
  }

  Future<Result<Topic>> toggleActive({
    required String topicId,
    required bool isActive,
  }) {
    if (topicId.trim().isEmpty) {
      return Future<Result<Topic>>.value(
        const Result<Topic>.failure(
          ValidationFailure(
            'Topic ID must not be empty',
            TopicErrorCodes.invalidTopicData,
          ),
        ),
      );
    }
    return _repository.toggleActive(topicId: topicId, isActive: isActive);
  }
}
