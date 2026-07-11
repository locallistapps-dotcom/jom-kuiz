import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/topic_repository.dart';
import '../datasources/topic_remote_data_source.dart';
import '../models/topic_model.dart';

/// Concrete [TopicRepository] backed by [TopicRemoteDataSource].
///
/// Converts [AppException]s from the datasource into [Failure]s via
/// [GlobalExceptionHandler] so the presentation layer stays exception-free.
class TopicRepositoryImpl implements TopicRepository {
  const TopicRepositoryImpl(this._remoteDataSource);

  final TopicRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Topic>>> getTopics({
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    TopicSortOrder sortOrder = TopicSortOrder.displayOrderAsc,
    bool? isActive,
  }) async {
    try {
      final List<TopicModel> models = await _remoteDataSource.getTopics(
        chapterId: chapterId,
        subjectId: subjectId,
        yearId: yearId,
        search: search,
        sortOrder: sortOrder,
        isActive: isActive,
      );
      return Result<List<Topic>>.success(
        models.map((TopicModel m) => m.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Result<List<Topic>>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Topic>> getTopicById({required String topicId}) async {
    try {
      final TopicModel model =
          await _remoteDataSource.getTopicById(topicId: topicId);
      return Result<Topic>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Topic>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Topic>> createTopic({
    required String chapterId,
    required String topicName,
    String? description,
    int displayOrder = 0,
  }) async {
    try {
      final TopicModel model = await _remoteDataSource.createTopic(
        CreateTopicRequest(
          chapterId: chapterId,
          topicName: topicName,
          description: description,
          displayOrder: displayOrder,
        ),
      );
      return Result<Topic>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Topic>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Topic>> updateTopic({
    required String topicId,
    required String chapterId,
    required String topicName,
    String? description,
    required int displayOrder,
    required bool isActive,
  }) async {
    try {
      final TopicModel model = await _remoteDataSource.updateTopic(
        topicId: topicId,
        request: UpdateTopicRequest(
          chapterId: chapterId,
          topicName: topicName,
          description: description,
          displayOrder: displayOrder,
          isActive: isActive,
        ),
      );
      return Result<Topic>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Topic>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteTopic({required String topicId}) async {
    try {
      await _remoteDataSource.deleteTopic(topicId: topicId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Topic>> toggleActive({
    required String topicId,
    required bool isActive,
  }) async {
    try {
      final TopicModel model = await _remoteDataSource.toggleActive(
        topicId: topicId,
        request: ToggleTopicActiveRequest(isActive: isActive),
      );
      return Result<Topic>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Topic>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
