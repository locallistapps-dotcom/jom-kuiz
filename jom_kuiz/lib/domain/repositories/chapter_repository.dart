import '../../core/utils/result.dart';
import '../entities/chapter.dart';

/// Abstract contract for Chapter CRUD operations.
///
/// The implementation is backed by Supabase REST (PostgREST) via the shared
/// Dio instance. All methods return [Result] — no exceptions escape this layer.
///
/// Chapters are always scoped to a (subjectId, yearId) pair. Passing null for
/// either filter in [getChapters] returns chapters across all subjects or years
/// respectively (admin use case).
abstract interface class ChapterRepository {
  /// Returns chapters, optionally filtered by [subjectId], [yearId],
  /// [search] text and sorted by [sortOrder].
  Future<Result<List<Chapter>>> getChapters({
    String? subjectId,
    String? yearId,
    String? search,
    ChapterSortOrder sortOrder,
    bool? isActive,
  });

  /// Returns a single chapter by primary key.
  Future<Result<Chapter>> getChapterById({required String chapterId});

  /// Creates a new chapter linked to a Subject and a Year.
  Future<Result<Chapter>> createChapter({
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    int displayOrder,
  });

  /// Updates all mutable fields of an existing chapter.
  Future<Result<Chapter>> updateChapter({
    required String chapterId,
    required String subjectId,
    required String yearId,
    required String chapterName,
    String? description,
    required int displayOrder,
    required bool isActive,
  });

  /// Hard-deletes a chapter. Returns [Result.success] with `null` on success.
  Future<Result<void>> deleteChapter({required String chapterId});

  /// Flips [Chapter.isActive] for the given [chapterId].
  Future<Result<Chapter>> toggleActive({
    required String chapterId,
    required bool isActive,
  });
}
