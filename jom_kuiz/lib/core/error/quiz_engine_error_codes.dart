/// Error codes for the Quiz Engine module.
///
/// Format: QUIZ_ENGINE-NNN
abstract final class QuizEngineErrorCodes {
  /// No questions are available for the selected topic / filter.
  static const String noQuestionsAvailable = 'QUIZ_ENGINE-001';

  /// The requested question count exceeds the available pool.
  static const String insufficientQuestions = 'QUIZ_ENGINE-002';

  /// The quiz session has already been completed.
  static const String sessionAlreadyCompleted = 'QUIZ_ENGINE-003';

  /// Failed to persist the session, answers, or result to the server.
  static const String persistenceFailed = 'QUIZ_ENGINE-004';

  /// Generic quiz engine failure.
  static const String quizEngineOperationFailed = 'QUIZ_ENGINE-005';
}
