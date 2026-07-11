import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/repositories/chapter_repository.dart';
import '../datasources/chapter_remote_data_source.dart';
import '../models/chapter_model.dart';

/// Concrete [ChapterRepository] backed by [ChapterRemoteDataSource].
///
/// Converts [AppException]s from the datasource into [Failure]s via
/// [GlobalExceptionHandler] so the presentation layer stays exception-free.
class ChapterRepositoryImpl implements ChapterRepository {
  const ChapterRepositoryImpl(this._remoteDataSource);

  final ChapterRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Chapter>>> getChapters({
    String? subjectId,
    String? yearId,
    String? search,
    ChapterSortOrder sortOrder = ChapterSortOrder.displayOrderAsc,
    bool? isActive,
  }) async {
    try {
      final List<ChapterModel> models = await _remoteDataSource.getChapters(
        subjectId: subjectId,
        yearId: yearId,
        search: search,
        sortOrder: sortOrder,
        isActive: isActive,
      );
      return Result<List<Chapter>>.success(
        models.map((ChapterModel m) => m.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Result<List<Chapter>>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Chapter>> getChapterById({required String chapterId}) async {
    try {
      final ChapterModel model =
          await _remoteDataSource.getChapterById(chapterId: chapterId);
      return Result<Chapter>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Chapter>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Chapter>> createChapter({
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    int displayOrder = 0,
  }) async {
    try {
      final ChapterModel model = await _remoteDataSource.createChapter(
        CreateChapterRequest(
          subjectId: subjectId,
          yearId: yearId,
          chapterName: chapterName,
          description: description,
          displayOrder: displayOrder,
        ),
      );
      return Result<Chapter>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Chapter>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Chapter>> updateChapter({
    required String chapterId,
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    required int displayOrder,
    required bool isActive,
  }) async {
    try {
      final ChapterModel model = await _remoteDataSource.updateChapter(
        chapterId: chapterId,
        request: UpdateChapterRequest(
          subjectId: subjectId,
          yearId: yearId,
          chapterName: chapterName,
          description: description,
          displayOrder: displayOrder,
          isActive: isActive,
        ),
      );
      return Result<Chapter>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Chapter>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteChapter({required String chapterId}) async {
    try {
      await _remoteDataSource.deleteChapter(chapterId: chapterId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Chapter>> toggleActive({
    required String chapterId,
    required bool isActive,
  }) async {
    try {
      final ChapterModel model = await _remoteDataSource.toggleActive(
        chapterId: chapterId,
        request: ToggleChapterActiveRequest(isActive: isActive),
      );
      return Result<Chapter>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Chapter>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
