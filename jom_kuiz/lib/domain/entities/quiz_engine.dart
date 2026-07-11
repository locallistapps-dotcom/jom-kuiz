import 'package:equatable/equatable.dart';

import 'question.dart';

// ── Phase state machine ───────────────────────────────────────────────────────

/// Sealed hierarchy that drives the [QuizEngineController] state machine.
///
/// ```
///   QuizIdle → QuizLoading → QuizPlaying → QuizFinished
///                         ↘             ↗
///                          QuizEngineError
/// ```
sealed class QuizEnginePhase extends Equatable {
  const QuizEnginePhase();
}

/// No active session. The Quiz Home screen shows browse / filter UI.
class QuizIdle extends QuizEnginePhase {
  const QuizIdle();
  @override
  List<Object?> get props => const <Object?>[];
}

/// Fetching questions from the Question Bank.
class QuizLoading extends QuizEnginePhase {
  const QuizLoading();
  @override
  List<Object?> get props => const <Object?>[];
}

/// Questions loaded; the user is actively answering.
class QuizPlaying extends QuizEnginePhase {
  const QuizPlaying({required this.session});
  final QuizEngineSession session;
  @override
  List<Object?> get props => <Object?>[session];
}

/// The quiz has been submitted and results are ready.
class QuizFinished extends QuizEnginePhase {
  const QuizFinished({required this.result});
  final QuizEngineResult result;
  @override
  List<Object?> get props => <Object?>[result];
}

/// Something went wrong — shows error + retry.
class QuizEngineError extends QuizEnginePhase {
  const QuizEngineError({required this.message});
  final String message;
  @override
  List<Object?> get props => <Object?>[message];
}

// ── Session ───────────────────────────────────────────────────────────────────

/// In-memory state for a quiz attempt.
///
/// Created by [QuizEngineController.startQuiz] and held entirely in client
/// memory until the user taps Finish, at which point the service layer
/// persists it to Supabase.
class QuizEngineSession extends Equatable {
  const QuizEngineSession({
    required this.sessionId,
    required this.topicId,
    required this.questions,
    required this.startedAt,
    this.answers = const <String, String>{},
    this.currentIndex = 0,
  });

  /// Client-generated UUID — assigned before server persistence.
  final String sessionId;

  /// The topic this quiz is drawn from.
  final String topicId;

  /// Ordered, shuffled subset of questions from the Question Bank.
  final List<Question> questions;

  /// Wall-clock time when the session started.
  final DateTime startedAt;

  /// Map of `questionId → answer string`.
  ///
  /// Format mirrors [Question.correctAnswer]:
  ///   MCQ          → 'A' | 'B' | 'C' | 'D'
  ///   True/False   → 'true' | 'false'
  ///   Fill Blank   → free text
  final Map<String, String> answers;

  /// 0-based index of the currently displayed question.
  final int currentIndex;

  // ── Computed ───────────────────────────────────────────────────────────────

  int get totalQuestions => questions.length;
  int get answeredCount => answers.length;
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == questions.length - 1;
  double get progress =>
      questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;

  Question get currentQuestion => questions[currentIndex];

  String? answerFor(String questionId) => answers[questionId];

  QuizEngineSession copyWith({
    Map<String, String>? answers,
    int? currentIndex,
  }) {
    return QuizEngineSession(
      sessionId: sessionId,
      topicId: topicId,
      questions: questions,
      startedAt: startedAt,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        sessionId,
        topicId,
        questions,
        startedAt,
        answers,
        currentIndex,
      ];
}

// ── Answer ────────────────────────────────────────────────────────────────────

/// A single answered (or skipped) question inside a completed quiz.
///
/// Carries the full [Question] so the review screen can display question text,
/// explanation, and explanationImageUrl without an extra round-trip.
class QuizEngineAnswer extends Equatable {
  const QuizEngineAnswer({
    required this.question,
    required this.givenAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final Question question;

  /// What the user selected/typed. Null means the question was skipped.
  final String? givenAnswer;

  /// Ground-truth correct answer (copied from [Question.correctAnswer]).
  final String correctAnswer;

  final bool isCorrect;

  @override
  List<Object?> get props => <Object?>[
        question,
        givenAnswer,
        correctAnswer,
        isCorrect,
      ];
}

// ── Result ────────────────────────────────────────────────────────────────────

/// The final aggregated outcome of a completed quiz attempt.
///
/// Built entirely client-side from [QuizEngineSession.answers] and then
/// persisted to Supabase by [QuizEngineRemoteDataSource.saveResult].
class QuizEngineResult extends Equatable {
  const QuizEngineResult({
    required this.sessionId,
    required this.topicId,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.percentage,
    required this.timeTakenSeconds,
    required this.completedAt,
    required this.answers,
  });

  final String sessionId;
  final String topicId;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;

  /// Questions not answered before the user tapped Finish.
  final int skippedCount;

  /// 0.0 – 100.0 (already multiplied).
  final double percentage;

  final int timeTakenSeconds;
  final DateTime completedAt;

  /// Ordered list matching the original quiz question order.
  final List<QuizEngineAnswer> answers;

  // ── Computed ───────────────────────────────────────────────────────────────

  String get timeTakenFormatted {
    final int m = timeTakenSeconds ~/ 60;
    final int s = timeTakenSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  /// Passes at 60 % correct.
  bool get isPassed => percentage >= 60;

  @override
  List<Object?> get props => <Object?>[
        sessionId,
        topicId,
        totalQuestions,
        correctCount,
        wrongCount,
        skippedCount,
        percentage,
        timeTakenSeconds,
        completedAt,
        answers,
      ];
}
