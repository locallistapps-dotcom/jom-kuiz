import '../../core/utils/result.dart';
import '../entities/question.dart';

/// Abstract contract for Question Bank CRUD operations.
///
/// The implementation is backed by Supabase REST (PostgREST) via the shared
/// Dio instance. All methods return [Result] — no exceptions escape this layer.
///
/// Hierarchy filters are additive. The most specific filter wins:
///   topicId ⊂ chapterId ⊂ (subjectId + yearId)
abstract interface class QuestionBankRepository {
  /// Returns questions filtered by any combination of hierarchy IDs, search
  /// text, type, difficulty, and active status.
  Future<Result<List<Question>>> getQuestions({
    String? topicId,
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    QuestionType? questionType,
    QuestionDifficulty? difficulty,
    bool? isActive,
    QuestionSortOrder sortOrder,
  });

  /// Returns a single question by primary key.
  Future<Result<Question>> getQuestionById({required String questionId});

  /// Returns a random sample of [count] active questions for a given [topicId].
  /// Used by the Quiz Engine — returns a [Result] rather than throwing.
  Future<Result<List<Question>>> getRandomQuestions({
    required String topicId,
    required int count,
  });

  /// Creates a new question.
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
    String? explanationImageUrl,
    String? explanationVideoUrl,
    String? questionImageUrl,
    String? reference,
  });

  /// Updates all mutable fields of an existing question.
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
    String? explanationImageUrl,
    String? explanationVideoUrl,
    String? questionImageUrl,
    String? reference,
    required bool isActive,
  });

  /// Hard-deletes a question.
  Future<Result<void>> deleteQuestion({required String questionId});

  /// Flips [Question.isActive] for the given [questionId].
  Future<Result<Question>> toggleActive({
    required String questionId,
    required bool isActive,
  });
}
