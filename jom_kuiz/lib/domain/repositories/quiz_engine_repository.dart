import '../../core/utils/result.dart';
import '../entities/quiz_session.dart';

/// Abstract contract for quiz-engine session management.
abstract interface class QuizEngineRepository {
  /// Starts a new quiz session for [childId] on [quizId].
  Future<Result<QuizSession>> startSession({
    required String quizId,
    required String childId,
  });

  /// Records an answer for [questionId] within [sessionId].
  Future<Result<QuizSession>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String answer,
  });

  /// Marks a session as completed and triggers result generation.
  Future<Result<QuizSession>> endSession({required String sessionId});

  /// Returns the current state of an in-progress session.
  Future<Result<QuizSession>> getSession({required String sessionId});
}
