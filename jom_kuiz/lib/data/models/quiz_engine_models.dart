import '../../domain/entities/quiz_engine.dart';

// ── Quiz Session model ────────────────────────────────────────────────────────

/// Wire format for the `quiz_sessions` Supabase table.
///
/// The session is written once, when the quiz is completed.
class QuizSessionPersistModel {
  const QuizSessionPersistModel({
    required this.id,
    required this.topicId,
    required this.questionCount,
    required this.startedAt,
    required this.completedAt,
  });

  final String id;
  final String topicId;
  final int questionCount;
  final DateTime startedAt;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'topic_id': topicId,
        'question_count': questionCount,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'is_completed': true,
      };
}

// ── Quiz Answer model ─────────────────────────────────────────────────────────

/// Wire format for a single row in the `quiz_answers` Supabase table.
class QuizAnswerPersistModel {
  const QuizAnswerPersistModel({
    required this.sessionId,
    required this.questionId,
    required this.givenAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final String sessionId;
  final String questionId;
  final String? givenAnswer;
  final String correctAnswer;
  final bool isCorrect;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'session_id': sessionId,
        'question_id': questionId,
        'given_answer': givenAnswer,
        'correct_answer': correctAnswer,
        'is_correct': isCorrect,
      };

  static QuizAnswerPersistModel fromEngineAnswer({
    required String sessionId,
    required QuizEngineAnswer answer,
  }) {
    return QuizAnswerPersistModel(
      sessionId: sessionId,
      questionId: answer.question.questionId,
      givenAnswer: answer.givenAnswer,
      correctAnswer: answer.correctAnswer,
      isCorrect: answer.isCorrect,
    );
  }
}

// ── Quiz Result model ─────────────────────────────────────────────────────────

/// Wire format for the `quiz_results` Supabase table.
class QuizResultPersistModel {
  const QuizResultPersistModel({
    required this.sessionId,
    required this.topicId,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.percentage,
    required this.timeTakenSeconds,
    required this.completedAt,
  });

  final String sessionId;
  final String topicId;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double percentage;
  final int timeTakenSeconds;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'session_id': sessionId,
        'topic_id': topicId,
        'total_questions': totalQuestions,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'skipped_count': skippedCount,
        'percentage': double.parse(percentage.toStringAsFixed(2)),
        'time_taken_seconds': timeTakenSeconds,
        'completed_at': completedAt.toIso8601String(),
      };

  static QuizResultPersistModel fromEngineResult(QuizEngineResult result) {
    return QuizResultPersistModel(
      sessionId: result.sessionId,
      topicId: result.topicId,
      totalQuestions: result.totalQuestions,
      correctCount: result.correctCount,
      wrongCount: result.wrongCount,
      skippedCount: result.skippedCount,
      percentage: result.percentage,
      timeTakenSeconds: result.timeTakenSeconds,
      completedAt: result.completedAt,
    );
  }
}
