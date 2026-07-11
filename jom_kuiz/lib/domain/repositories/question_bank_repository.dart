import '../../core/utils/result.dart';
import '../entities/question.dart';

/// Abstract contract for question-bank operations.
abstract interface class QuestionBankRepository {
  /// Returns all questions for a given [topicId].
  Future<Result<List<Question>>> getQuestions({required String topicId});

  /// Returns a single question by [questionId].
  Future<Result<Question>> getQuestionById({required String questionId});

  /// Returns a random selection of [count] questions for [topicId].
  Future<Result<List<Question>>> getRandomQuestions({
    required String topicId,
    required int count,
  });
}
