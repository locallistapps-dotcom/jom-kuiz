import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/error/quiz_engine_error_codes.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_engine.dart';
import '../../domain/repositories/question_bank_repository.dart';
import '../../domain/repositories/quiz_engine_repository.dart';
import '../providers/quiz_engine_providers.dart';

// ── Provider declaration ──────────────────────────────────────────────────────

/// Global state machine for a single quiz attempt.
///
/// All screens in the quiz flow (Home → Start → Quiz → Result → Review)
/// consume this one provider. The state is held in memory until the user
/// resets or starts a new quiz.
final NotifierProvider<QuizEngineController, QuizEnginePhase>
    quizEngineControllerProvider =
    NotifierProvider<QuizEngineController, QuizEnginePhase>(
  QuizEngineController.new,
);

// ── Controller ────────────────────────────────────────────────────────────────

class QuizEngineController extends Notifier<QuizEnginePhase> {
  @override
  QuizEnginePhase build() => const QuizIdle();

  QuizEngineRepository get _repo =>
      ref.read(quizEngineRepositoryProvider);

  QuestionBankRepository get _qbRepo =>
      ref.read(quizQuestionBankRepositoryProvider);

  // ── State helpers ──────────────────────────────────────────────────────────

  QuizEngineSession? get _session {
    final QuizEnginePhase s = state;
    if (s is QuizPlaying) return s.session;
    return null;
  }

  // ── Start ──────────────────────────────────────────────────────────────────

  /// Loads questions from the Question Bank and transitions to [QuizPlaying].
  ///
  /// [count] = 0 means "all available questions".
  /// Questions are shuffled before the session begins.
  Future<void> startQuiz({
    required String topicId,
    required int count,
  }) async {
    if (topicId.trim().isEmpty) {
      state = const QuizEngineError(message: 'Please select a topic first.');
      return;
    }
    state = const QuizLoading();

    try {
      final Result<List<Question>> result = await _qbRepo.getRandomQuestions(
        topicId: topicId,
        count: count == 0 ? 9999 : count, // 9999 = fetch all, trimmed below
      );

      result.when(
        success: (List<Question> raw) {
          // Filter active questions only (server should already do this, but
          // guard client-side to be safe).
          final List<Question> active =
              raw.where((Question q) => q.isActive).toList();

          if (active.isEmpty) {
            state = const QuizEngineError(
              message:
                  'No questions are available for this topic yet. Please try another topic.',
            );
            return;
          }

          // Shuffle for randomness (datasource already uses random() order,
          // shuffle again for extra safety against deterministic server seeds).
          final List<Question> shuffled = List<Question>.from(active)
            ..shuffle(math.Random());

          // Trim to requested count when fetching "all" was used.
          final List<Question> questions =
              (count == 0 || shuffled.length <= count)
                  ? shuffled
                  : shuffled.sublist(0, count);

          final String sessionId = _generateUuid();

          state = QuizPlaying(
            session: QuizEngineSession(
              sessionId: sessionId,
              topicId: topicId,
              questions: questions,
              startedAt: DateTime.now().toUtc(),
            ),
          );
        },
        failure: (Failure f) {
          state = QuizEngineError(message: f.message);
        },
      );
    } catch (e) {
      // Catch unexpected exceptions (e.g. type errors during parsing) and
      // surface the real message instead of leaving the state as QuizLoading.
      state = QuizEngineError(message: 'Quiz load failed: $e');
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void goToNext() {
    final QuizEngineSession? s = _session;
    if (s == null || s.isLast) return;
    state = QuizPlaying(session: s.copyWith(currentIndex: s.currentIndex + 1));
  }

  void goToPrevious() {
    final QuizEngineSession? s = _session;
    if (s == null || s.isFirst) return;
    state = QuizPlaying(session: s.copyWith(currentIndex: s.currentIndex - 1));
  }

  void goToIndex(int index) {
    final QuizEngineSession? s = _session;
    if (s == null) return;
    final int clamped = index.clamp(0, s.totalQuestions - 1);
    state = QuizPlaying(session: s.copyWith(currentIndex: clamped));
  }

  // ── Answer recording ───────────────────────────────────────────────────────

  /// Saves the user's answer for [questionId], replacing any prior answer.
  /// Called automatically whenever the user changes their selection.
  void recordAnswer({required String questionId, required String answer}) {
    final QuizEngineSession? s = _session;
    if (s == null) return;
    final Map<String, String> updated =
        Map<String, String>.from(s.answers)..[questionId] = answer;
    state = QuizPlaying(session: s.copyWith(answers: updated));
  }

  /// Clears a previously recorded answer (e.g. user de-selects in Fill Blank).
  void clearAnswer({required String questionId}) {
    final QuizEngineSession? s = _session;
    if (s == null) return;
    final Map<String, String> updated =
        Map<String, String>.from(s.answers)..remove(questionId);
    state = QuizPlaying(session: s.copyWith(answers: updated));
  }

  // ── Finish ─────────────────────────────────────────────────────────────────

  /// Scores the quiz, builds a [QuizEngineResult], and persists to Supabase.
  ///
  /// Returns the [QuizEngineResult] wrapped in [Result]. On persistence
  /// failure the result is still returned — the quiz experience is never
  /// blocked by a save error. Transitions state to [QuizFinished].
  Future<Result<QuizEngineResult>> finishQuiz() async {
    final QuizEngineSession? s = _session;
    if (s == null) {
      return const Result<QuizEngineResult>.failure(
        ValidationFailure(
          'No active quiz session.',
          QuizEngineErrorCodes.quizEngineOperationFailed,
        ),
      );
    }

    final DateTime completedAt = DateTime.now().toUtc();
    final int elapsed =
        completedAt.difference(s.startedAt).inSeconds.abs();

    // Build answer review list
    final List<QuizEngineAnswer> answers = s.questions.map((Question q) {
      final String? given = s.answers[q.questionId];
      final bool correct = given != null &&
          _answersMatch(given, q.correctAnswer, q.questionType);
      return QuizEngineAnswer(
        question: q,
        givenAnswer: given,
        correctAnswer: q.correctAnswer,
        isCorrect: correct,
      );
    }).toList();

    final int correctCount =
        answers.where((QuizEngineAnswer a) => a.isCorrect).length;
    final int skippedCount =
        answers.where((QuizEngineAnswer a) => a.givenAnswer == null).length;
    final int wrongCount =
        answers.length - correctCount - skippedCount;
    final double percentage = s.totalQuestions > 0
        ? (correctCount / s.totalQuestions) * 100.0
        : 0.0;

    final QuizEngineResult result = QuizEngineResult(
      sessionId: s.sessionId,
      topicId: s.topicId,
      totalQuestions: s.totalQuestions,
      correctCount: correctCount,
      wrongCount: wrongCount,
      skippedCount: skippedCount,
      percentage: percentage,
      timeTakenSeconds: elapsed,
      completedAt: completedAt,
      answers: answers,
    );

    // Persist (best-effort; don't block the UX on network issues).
    await _repo.saveSession(session: s);
    await _repo.saveAnswers(sessionId: s.sessionId, answers: answers);
    await _repo.saveResult(result: result);

    state = QuizFinished(result: result);
    return Result<QuizEngineResult>.success(result);
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  /// Clears the current session and returns to [QuizIdle].
  void reset() {
    state = const QuizIdle();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Case-insensitive comparison for MCQ (A/a) and True/False (true/TRUE).
  bool _answersMatch(
      String given, String correct, QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return given.trim().toUpperCase() ==
            correct.trim().toUpperCase();
      case QuestionType.trueFalse:
        return given.trim().toLowerCase() ==
            correct.trim().toLowerCase();
      case QuestionType.fillInTheBlank:
        return given.trim().toLowerCase() ==
            correct.trim().toLowerCase();
    }
  }

  /// Generates a valid v4 UUID using dart:math (no external package).
  ///
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (36 chars)
  /// Group sizes: 8-4-4-4-12 hex chars separated by hyphens.
  String _generateUuid() {
    final math.Random rng = math.Random();
    String hex(int bytes) => List<int>.generate(bytes, (_) => rng.nextInt(256))
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    // Group 3: '4' + 3 random hex chars (version 4)
    // Group 4: variant nibble (8–b) + 3 random hex chars
    return '${hex(4)}-${hex(2)}-4${hex(2).substring(1)}-'
        '${(8 + rng.nextInt(4)).toRadixString(16)}${hex(2).substring(1)}-'
        '${hex(6)}';
  }
}
