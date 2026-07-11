import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/quiz.dart';
import '../providers/child_providers.dart';

/// Manages the quiz list and handles quiz submission for the current child.
final AsyncNotifierProvider<QuizController, List<Quiz>>
    quizControllerProvider =
    AsyncNotifierProvider<QuizController, List<Quiz>>(QuizController.new);

class QuizController extends AsyncNotifier<List<Quiz>> {
  @override
  Future<List<Quiz>> build() async {
    final Result<List<Quiz>> result =
        await ref.watch(childServiceProvider).getQuizList();
    return result.when(
      success: (List<Quiz> list) => list,
      failure: (Failure failure) => throw failure,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<Quiz>>.loading();
    state = await AsyncValue.guard<List<Quiz>>(() async {
      final Result<List<Quiz>> result =
          await ref.read(childServiceProvider).getQuizList();
      return result.when(success: (l) => l, failure: (f) => throw f);
    });
  }

  /// Submits a quiz attempt. Returns [Result.success] with the new
  /// [QuizResult] on success, or [Result.failure] with the error.
  ///
  /// Callers (screens) are responsible for showing the result to the user.
  Future<Result<QuizResult>> submitQuiz({
    required String quizId,
    required Map<String, dynamic> answers,
    required int timeTakenSeconds,
  }) async {
    final String childId = ref.read(currentChildIdProvider);
    return ref.read(childServiceProvider).submitQuiz(
          quizId: quizId,
          childId: childId,
          answers: answers,
          timeTakenSeconds: timeTakenSeconds,
        );
  }
}
