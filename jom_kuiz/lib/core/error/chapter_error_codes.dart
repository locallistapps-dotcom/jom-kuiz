/// Error codes for the Chapter module.
///
/// Format: CHAPTER-NNN
abstract final class ChapterErrorCodes {
  /// No chapter found for the given ID.
  static const String chapterNotFound = 'CHAPTER-001';

  /// A chapter with the same name already exists in this Subject + Year slot.
  static const String duplicateChapterName = 'CHAPTER-002';

  /// The submitted chapter data failed validation.
  static const String invalidChapterData = 'CHAPTER-003';

  /// The chapter could not be deleted (e.g. it has dependent topics).
  static const String chapterDeleteFailed = 'CHAPTER-004';

  /// Generic server-side failure for any chapter operation.
  static const String chapterOperationFailed = 'CHAPTER-005';
}
