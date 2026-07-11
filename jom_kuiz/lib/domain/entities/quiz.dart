import 'package:equatable/equatable.dart';

/// Difficulty level of a quiz.
enum QuizDifficulty { easy, medium, hard }

/// A quiz available for a child to attempt.
class Quiz extends Equatable {
  const Quiz({
    required this.quizId,
    required this.title,
    required this.subject,
    required this.questionCount,
    required this.durationMinutes,
    required this.difficulty,
    required this.createdAt,
    this.description,
  });

  final String quizId;
  final String title;
  final String? description;
  final String subject;
  final int questionCount;
  final int durationMinutes;
  final QuizDifficulty difficulty;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
        quizId,
        title,
        description,
        subject,
        questionCount,
        durationMinutes,
        difficulty,
        createdAt,
      ];
}

/// The result of a completed quiz attempt.
class QuizResult extends Equatable {
  const QuizResult({
    required this.resultId,
    required this.quizId,
    required this.quizTitle,
    required this.childId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.timeTakenSeconds,
  });

  final String resultId;
  final String quizId;
  final String quizTitle;
  final String childId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final int timeTakenSeconds;

  /// Score as a value between 0.0 and 1.0.
  double get percentage =>
      totalQuestions > 0 ? score / totalQuestions : 0.0;

  /// Passes at 60 % correct.
  bool get isPassed => percentage >= 0.6;

  @override
  List<Object?> get props => <Object?>[
        resultId,
        quizId,
        quizTitle,
        childId,
        score,
        totalQuestions,
        completedAt,
        timeTakenSeconds,
      ];
}
