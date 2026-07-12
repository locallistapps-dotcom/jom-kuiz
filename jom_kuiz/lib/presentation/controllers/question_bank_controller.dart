import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/question.dart';
import '../providers/question_bank_providers.dart';

// ── Provider declaration ──────────────────────────────────────────────────────

/// Loads and caches the question list. Reacts to all six filter/sort
/// providers. Client-side search and difficulty sorting are applied by
/// [filteredQuestionsProvider] for instant UI response.
final AsyncNotifierProvider<QuestionBankController, List<Question>>
    questionBankControllerProvider =
    AsyncNotifierProvider<QuestionBankController, List<Question>>(
  QuestionBankController.new,
);

/// Derived provider: applies client-side search query and sort order to the
/// full list cached by [questionBankControllerProvider].
final Provider<List<Question>> filteredQuestionsProvider =
    Provider<List<Question>>((Ref ref) {
  final AsyncValue<List<Question>> async =
      ref.watch(questionBankControllerProvider);
  final String query =
      ref.watch(questionSearchQueryProvider).trim().toLowerCase();
  final QuestionSortOrder sort = ref.watch(questionSortOrderProvider);

  final List<Question> all = async.valueOrNull ?? <Question>[];

  final List<Question> filtered = query.isEmpty
      ? all
      : all
          .where((Question q) =>
              q.questionText.toLowerCase().contains(query))
          .toList();

  filtered.sort((Question a, Question b) {
    switch (sort) {
      case QuestionSortOrder.createdAtDesc:
        return b.createdAt.compareTo(a.createdAt);
      case QuestionSortOrder.textAsc:
        return a.questionText
            .toLowerCase()
            .compareTo(b.questionText.toLowerCase());
      case QuestionSortOrder.difficultyAsc:
        return _difficultyRank(a.difficulty)
            .compareTo(_difficultyRank(b.difficulty));
      case QuestionSortOrder.hierarchyAsc:
        // In the quiz bank the hierarchy sort falls back to newest-first
        // (topic-level ordering is handled server-side for the admin view).
        return b.createdAt.compareTo(a.createdAt);
    }
  });

  return filtered;
});

int _difficultyRank(QuestionDifficulty d) {
  switch (d) {
    case QuestionDifficulty.easy:
      return 0;
    case QuestionDifficulty.medium:
      return 1;
    case QuestionDifficulty.hard:
      return 2;
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class QuestionBankController extends AsyncNotifier<List<Question>> {
  @override
  Future<List<Question>> build() async {
    final QuestionSortOrder sort = ref.watch(questionSortOrderProvider);
    final String topicId = ref.watch(questionTopicFilterProvider);
    final String chapterId = ref.watch(questionChapterFilterProvider);
    final String subjectId = ref.watch(questionSubjectFilterProvider);
    final String yearId = ref.watch(questionYearFilterProvider);
    final QuestionType? typeFilter = ref.watch(questionTypeFilterProvider);
    final QuestionDifficulty? diffFilter =
        ref.watch(questionDifficultyFilterProvider);

    final Result<List<Question>> result =
        await ref.watch(questionBankServiceProvider).getQuestions(
              topicId: topicId.isEmpty ? null : topicId,
              chapterId: chapterId.isEmpty ? null : chapterId,
              subjectId: subjectId.isEmpty ? null : subjectId,
              yearId: yearId.isEmpty ? null : yearId,
              questionType: typeFilter,
              difficulty: diffFilter,
              sortOrder: sort,
            );

    return result.when(
      success: (List<Question> list) => list,
      failure: (Failure failure) => throw failure,
    );
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncValue<List<Question>>.loading();
    state = await AsyncValue.guard<List<Question>>(() async {
      final QuestionSortOrder sort = ref.read(questionSortOrderProvider);
      final String topicId = ref.read(questionTopicFilterProvider);
      final String chapterId = ref.read(questionChapterFilterProvider);
      final String subjectId = ref.read(questionSubjectFilterProvider);
      final String yearId = ref.read(questionYearFilterProvider);
      final QuestionType? typeFilter = ref.read(questionTypeFilterProvider);
      final QuestionDifficulty? diffFilter =
          ref.read(questionDifficultyFilterProvider);

      final Result<List<Question>> result =
          await ref.read(questionBankServiceProvider).getQuestions(
                topicId: topicId.isEmpty ? null : topicId,
                chapterId: chapterId.isEmpty ? null : chapterId,
                subjectId: subjectId.isEmpty ? null : subjectId,
                yearId: yearId.isEmpty ? null : yearId,
                questionType: typeFilter,
                difficulty: diffFilter,
                sortOrder: sort,
              );
      return result.when(
        success: (List<Question> list) => list,
        failure: (Failure f) => throw f,
      );
    });
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
    String? explanationImageUrl,
    String? explanationVideoUrl,
    String? questionImageUrl,
    String? reference,
  }) async {
    final Result<Question> result =
        await ref.read(questionBankServiceProvider).createQuestion(
              topicId: topicId,
              questionText: questionText,
              questionType: questionType,
              difficulty: difficulty,
              correctAnswer: correctAnswer,
              optionA: optionA,
              optionB: optionB,
              optionC: optionC,
              optionD: optionD,
              explanation: explanation,
              explanationImageUrl: explanationImageUrl,
              explanationVideoUrl: explanationVideoUrl,
              questionImageUrl: questionImageUrl,
              reference: reference,
            );

    result.when(
      success: (Question created) {
        final List<Question> current =
            List<Question>.from(state.valueOrNull ?? <Question>[])
              ..add(created);
        state = AsyncValue<List<Question>>.data(current);
      },
      failure: (_) {},
    );
    return result;
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
    String? explanationImageUrl,
    String? explanationVideoUrl,
    String? questionImageUrl,
    String? reference,
    required bool isActive,
  }) async {
    final Result<Question> result =
        await ref.read(questionBankServiceProvider).updateQuestion(
              questionId: questionId,
              topicId: topicId,
              questionText: questionText,
              questionType: questionType,
              difficulty: difficulty,
              correctAnswer: correctAnswer,
              optionA: optionA,
              optionB: optionB,
              optionC: optionC,
              optionD: optionD,
              explanation: explanation,
              explanationImageUrl: explanationImageUrl,
              explanationVideoUrl: explanationVideoUrl,
              questionImageUrl: questionImageUrl,
              reference: reference,
              isActive: isActive,
            );

    result.when(
      success: (Question updated) {
        final List<Question> current =
            (state.valueOrNull ?? <Question>[]).map((Question q) {
          return q.questionId == updated.questionId ? updated : q;
        }).toList();
        state = AsyncValue<List<Question>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> deleteQuestion({required String questionId}) async {
    final Result<void> result = await ref
        .read(questionBankServiceProvider)
        .deleteQuestion(questionId: questionId);

    result.when(
      success: (_) {
        final List<Question> current =
            (state.valueOrNull ?? <Question>[])
                .where((Question q) => q.questionId != questionId)
                .toList();
        state = AsyncValue<List<Question>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<Question>> toggleActive({
    required String questionId,
    required bool isActive,
  }) async {
    final Result<Question> result = await ref
        .read(questionBankServiceProvider)
        .toggleActive(questionId: questionId, isActive: isActive);

    result.when(
      success: (Question updated) {
        final List<Question> current =
            (state.valueOrNull ?? <Question>[]).map((Question q) {
          return q.questionId == updated.questionId ? updated : q;
        }).toList();
        state = AsyncValue<List<Question>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }
}
