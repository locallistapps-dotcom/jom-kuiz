import '../../core/utils/result.dart';
import '../entities/chapter.dart';

/// Abstract contract for chapter catalogue operations.
abstract interface class ChapterRepository {
  /// Returns all chapters for a given [subjectId] and [yearId],
  /// ordered by [Chapter.order] ascending.
  Future<Result<List<Chapter>>> getChapters({
    required String subjectId,
    required String yearId,
  });

  /// Returns a single chapter by [chapterId].
  Future<Result<Chapter>> getChapterById({required String chapterId});
}
