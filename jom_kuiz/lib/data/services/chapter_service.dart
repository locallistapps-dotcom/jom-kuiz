import '../../core/error/chapter_error_codes.dart';
import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/repositories/chapter_repository.dart';

/// Orchestrates Chapter business flows on top of [ChapterRepository].
///
/// Handles input validation before delegating to the repository so the
/// controller layer never talks to the repository directly.
class ChapterService {
  const ChapterService({required ChapterRepository repository})
      : _repository = repository;

  final ChapterRepository _repository;

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Result<List<Chapter>>> getChapters({
    String? subjectId,
    String? yearId,
    String? search,
    ChapterSortOrder sortOrder = ChapterSortOrder.displayOrderAsc,
    bool? isActive,
  }) {
    return _repository.getChapters(
      subjectId:
          (subjectId?.trim().isNotEmpty ?? false) ? subjectId!.trim() : null,
      yearId: (yearId?.trim().isNotEmpty ?? false) ? yearId!.trim() : null,
      search: (search?.trim().isNotEmpty ?? false) ? search!.trim() : null,
      sortOrder: sortOrder,
      isActive: isActive,
    );
  }

  Future<Result<Chapter>> getChapterById({required String chapterId}) {
    if (chapterId.trim().isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Chapter ID must not be empty',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    return _repository.getChapterById(chapterId: chapterId);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Chapter>> createChapter({
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    int displayOrder = 0,
  }) {
    final String name = chapterName.trim();
    final String sid = subjectId.trim();
    final String yid = yearId.trim();

    if (sid.isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Subject ID is required',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (yid.isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Year ID is required',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (name.isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Chapter name is required',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (name.length > 150) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Chapter name must not exceed 150 characters',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }

    final String? desc =
        (description?.trim().isNotEmpty ?? false) ? description!.trim() : null;

    return _repository.createChapter(
      subjectId: sid,
      yearId: yid,
      chapterName: name,
      description: desc,
      displayOrder: displayOrder,
    );
  }

  Future<Result<Chapter>> updateChapter({
    required String chapterId,
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    required int displayOrder,
    required bool isActive,
  }) {
    final String id = chapterId.trim();
    final String name = chapterName.trim();
    final String sid = subjectId.trim();
    final String yid = yearId.trim();

    if (id.isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Chapter ID must not be empty',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (sid.isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Subject ID is required',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (yid.isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Year ID is required',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (name.isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Chapter name is required',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (name.length > 150) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Chapter name must not exceed 150 characters',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }

    final String? desc =
        (description?.trim().isNotEmpty ?? false) ? description!.trim() : null;

    return _repository.updateChapter(
      chapterId: id,
      subjectId: sid,
      yearId: yid,
      chapterName: name,
      description: desc,
      displayOrder: displayOrder,
      isActive: isActive,
    );
  }

  Future<Result<void>> deleteChapter({required String chapterId}) {
    if (chapterId.trim().isEmpty) {
      return Future<Result<void>>.value(
        const Result<void>.failure(
          ValidationFailure(
            'Chapter ID must not be empty',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    return _repository.deleteChapter(chapterId: chapterId);
  }

  Future<Result<Chapter>> toggleActive({
    required String chapterId,
    required bool isActive,
  }) {
    if (chapterId.trim().isEmpty) {
      return Future<Result<Chapter>>.value(
        const Result<Chapter>.failure(
          ValidationFailure(
            'Chapter ID must not be empty',
            ChapterErrorCodes.invalidChapterData,
          ),
        ),
      );
    }
    return _repository.toggleActive(chapterId: chapterId, isActive: isActive);
  }
}
