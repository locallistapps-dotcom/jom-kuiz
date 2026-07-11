import '../../core/error/failure.dart';
import '../../core/error/question_bank_error_codes.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_bank_repository.dart';

/// Orchestrates Question Bank business flows on top of [QuestionBankRepository].
///
/// Validates all inputs and enforces question-type-specific rules before
/// delegating to the repository.
///
/// Type rules:
///   MCQ          — optionA + optionB required; correctAnswer ∈ {A, B, C, D}
///   True/False   — no options; correctAnswer ∈ {true, false}
///   Fill Blank   — no options; correctAnswer is any non-empty string
class QuestionBankService {
  const QuestionBankService({required QuestionBankRepository repository})
      : _repository = repository;

  final QuestionBankRepository _repository;

  static const Set<String> _mcqAnswers = <String>{'A', 'B', 'C', 'D'};
  static const Set<String> _tfAnswers = <String>{'true', 'false'};

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Result<List<Question>>> getQuestions({
    String? topicId,
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    QuestionType? questionType,
    QuestionDifficulty? difficulty,
    bool? isActive,
    QuestionSortOrder sortOrder = QuestionSortOrder.createdAtDesc,
  }) {
    return _repository.getQuestions(
      topicId: _clean(topicId),
      chapterId: _clean(chapterId),
      subjectId: _clean(subjectId),
      yearId: _clean(yearId),
      search: _clean(search),
      questionType: questionType,
      difficulty: difficulty,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  Future<Result<Question>> getQuestionById({required String questionId}) {
    if (questionId.trim().isEmpty) {
      return _fail('Question ID must not be empty');
    }
    return _repository.getQuestionById(questionId: questionId);
  }

  Future<Result<List<Question>>> getRandomQuestions({
    required String topicId,
    required int count,
  }) {
    if (topicId.trim().isEmpty) {
      return Future<Result<List<Question>>>.value(
        const Result<List<Question>>.failure(
          ValidationFailure(
            'Topic ID is required',
            QuestionBankErrorCodes.invalidQuestionData,
          ),
        ),
      );
    }
    if (count < 1) {
      return Future<Result<List<Question>>>.value(
        const Result<List<Question>>.failure(
          ValidationFailure(
            'Count must be at least 1',
            QuestionBankErrorCodes.invalidQuestionData,
          ),
        ),
      );
    }
    return _repository.getRandomQuestions(topicId: topicId, count: count);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Question>> createQuestion({
    required String topicId,
    required String questionText,
    required QuestionType questionType,
    required QuestionDifficulty difficulty,
    required String correctAnswer,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? explanation,
  }) {
    final Result<void>? err = _validateMutation(
      topicId: topicId,
      questionText: questionText,
      questionType: questionType,
      correctAnswer: correctAnswer,
      optionA: optionA,
      optionB: optionB,
    );
    if (err != null) return Future<Result<Question>>.value(err.asQuestionResult());

    final _Cleaned c = _cleanOptions(questionType,
        optionA: optionA,
        optionB: optionB,
        optionC: optionC,
        optionD: optionD);

    return _repository.createQuestion(
      topicId: topicId.trim(),
      questionText: questionText.trim(),
      questionType: questionType,
      difficulty: difficulty,
      correctAnswer: correctAnswer.trim(),
      optionA: c.a,
      optionB: c.b,
      optionC: c.c,
      optionD: c.d,
      explanation: _clean(explanation),
    );
  }

  Future<Result<Question>> updateQuestion({
    required String questionId,
    required String topicId,
    required String questionText,
    required QuestionType questionType,
    required QuestionDifficulty difficulty,
    required String correctAnswer,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? explanation,
    required bool isActive,
  }) {
    if (questionId.trim().isEmpty) {
      return _fail('Question ID must not be empty');
    }
    final Result<void>? err = _validateMutation(
      topicId: topicId,
      questionText: questionText,
      questionType: questionType,
      correctAnswer: correctAnswer,
      optionA: optionA,
      optionB: optionB,
    );
    if (err != null) return Future<Result<Question>>.value(err.asQuestionResult());

    final _Cleaned c = _cleanOptions(questionType,
        optionA: optionA,
        optionB: optionB,
        optionC: optionC,
        optionD: optionD);

    return _repository.updateQuestion(
      questionId: questionId.trim(),
      topicId: topicId.trim(),
      questionText: questionText.trim(),
      questionType: questionType,
      difficulty: difficulty,
      correctAnswer: correctAnswer.trim(),
      optionA: c.a,
      optionB: c.b,
      optionC: c.c,
      optionD: c.d,
      explanation: _clean(explanation),
      isActive: isActive,
    );
  }

  Future<Result<void>> deleteQuestion({required String questionId}) {
    if (questionId.trim().isEmpty) {
      return Future<Result<void>>.value(
        const Result<void>.failure(
          ValidationFailure(
            'Question ID must not be empty',
            QuestionBankErrorCodes.invalidQuestionData,
          ),
        ),
      );
    }
    return _repository.deleteQuestion(questionId: questionId);
  }

  Future<Result<Question>> toggleActive({
    required String questionId,
    required bool isActive,
  }) {
    if (questionId.trim().isEmpty) {
      return _fail('Question ID must not be empty');
    }
    return _repository.toggleActive(questionId: questionId, isActive: isActive);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String? _clean(String? s) =>
      (s != null && s.trim().isNotEmpty) ? s.trim() : null;

  Future<Result<Question>> _fail(String message) {
    return Future<Result<Question>>.value(
      Result<Question>.failure(
        ValidationFailure(message, QuestionBankErrorCodes.invalidQuestionData),
      ),
    );
  }

  /// Validates fields common to create and update.
  /// Returns a [Result<void>.failure] on the first broken rule, null if valid.
  Result<void>? _validateMutation({
    required String topicId,
    required String questionText,
    required QuestionType questionType,
    required String correctAnswer,
    String? optionA,
    String? optionB,
  }) {
    if (topicId.trim().isEmpty) {
      return const Result<void>.failure(ValidationFailure(
          'Topic ID is required', QuestionBankErrorCodes.invalidQuestionData));
    }
    if (questionText.trim().isEmpty) {
      return const Result<void>.failure(ValidationFailure(
          'Question text is required',
          QuestionBankErrorCodes.invalidQuestionData));
    }
    if (questionText.trim().length > 1000) {
      return const Result<void>.failure(ValidationFailure(
          'Question text must not exceed 1000 characters',
          QuestionBankErrorCodes.invalidQuestionData));
    }
    if (correctAnswer.trim().isEmpty) {
      return const Result<void>.failure(ValidationFailure(
          'Correct answer is required',
          QuestionBankErrorCodes.invalidQuestionData));
    }

    switch (questionType) {
      case QuestionType.mcq:
        if ((optionA?.trim().isEmpty ?? true) ||
            (optionB?.trim().isEmpty ?? true)) {
          return const Result<void>.failure(ValidationFailure(
              'MCQ questions require at least Option A and Option B',
              QuestionBankErrorCodes.invalidQuestionData));
        }
        if (!_mcqAnswers.contains(correctAnswer.trim().toUpperCase())) {
          return const Result<void>.failure(ValidationFailure(
              "Correct answer must be 'A', 'B', 'C', or 'D'",
              QuestionBankErrorCodes.invalidQuestionData));
        }
        break;
      case QuestionType.trueFalse:
        if (!_tfAnswers.contains(correctAnswer.trim().toLowerCase())) {
          return const Result<void>.failure(ValidationFailure(
              "Correct answer must be 'true' or 'false'",
              QuestionBankErrorCodes.invalidQuestionData));
        }
        break;
      case QuestionType.fillInTheBlank:
        // Any non-empty string is valid — already checked above.
        break;
    }
    return null;
  }

  /// Returns null-ified option fields for non-MCQ types.
  _Cleaned _cleanOptions(
    QuestionType type, {
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
  }) {
    if (type != QuestionType.mcq) {
      return const _Cleaned(null, null, null, null);
    }
    return _Cleaned(
      _clean(optionA),
      _clean(optionB),
      _clean(optionC),
      _clean(optionD),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Cleaned {
  const _Cleaned(this.a, this.b, this.c, this.d);
  final String? a, b, c, d;
}

extension _ResultExt on Result<void> {
  Result<Question> asQuestionResult() {
    return when(
      success: (_) => throw StateError('unreachable'),
      failure: (Failure f) => Result<Question>.failure(f),
    );
  }
}
