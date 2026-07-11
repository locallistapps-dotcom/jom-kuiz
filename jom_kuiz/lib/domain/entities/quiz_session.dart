import 'package:equatable/equatable.dart';

/// Represents an active quiz-engine session for a child.
///
/// Tracks progress through a quiz attempt in real time.
/// A completed session is persisted as a [QuizResult] (see quiz.dart).
class QuizSession extends Equatable {
  const QuizSession({
    required this.sessionId,
    required this.quizId,
    required this.childId,
    required this.startedAt,
    required this.totalQuestions,
    this.currentQuestionIndex = 0,
    this.answers = const <String, String>{},
    this.isCompleted = false,
  });

  final String sessionId;
  final String quizId;
  final String childId;
  final DateTime startedAt;
  final int totalQuestions;

  /// Zero-based index of the question currently being answered.
  final int currentQuestionIndex;

  /// Map of questionId → chosen answer string.
  final Map<String, String> answers;

  final bool isCompleted;

  /// Number of questions answered so far.
  int get answeredCount => answers.length;

  @override
  List<Object?> get props => <Object?>[
        sessionId,
        quizId,
        childId,
        startedAt,
        totalQuestions,
        currentQuestionIndex,
        answers,
        isCompleted,
      ];
}
