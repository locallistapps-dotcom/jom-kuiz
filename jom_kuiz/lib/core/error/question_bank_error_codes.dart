/// Error codes for the Question Bank module.
///
/// Format: QUESTION-NNN
abstract final class QuestionBankErrorCodes {
  /// No question found for the given ID.
  static const String questionNotFound = 'QUESTION-001';

  /// A question with the same text already exists in this topic.
  static const String duplicateQuestionText = 'QUESTION-002';

  /// The submitted question data failed validation.
  static const String invalidQuestionData = 'QUESTION-003';

  /// The question could not be deleted.
  static const String questionDeleteFailed = 'QUESTION-004';

  /// Generic server-side failure for any question operation.
  static const String questionOperationFailed = 'QUESTION-005';
}
