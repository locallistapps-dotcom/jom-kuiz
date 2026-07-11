import '../../core/utils/result.dart';

// QuizResult entity is defined in lib/domain/entities/quiz.dart
// to co-locate it with the Quiz entity it references.
import '../entities/quiz.dart';

/// Abstract contract for quiz-result retrieval.
abstract interface class QuizResultRepository {
  /// Returns all quiz results for [childId], newest first.
  Future<Result<List<QuizResult>>> getResults({required String childId});

  /// Returns a single result by [resultId].
  Future<Result<QuizResult>> getResultById({required String resultId});
}
