import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../data/services/admin_question_service.dart';
import '../../data/services/question_bank_service.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/year.dart';
import '../providers/admin_question_providers.dart';
import '../providers/chapter_providers.dart';
import '../providers/question_bank_providers.dart';
import '../providers/subject_providers.dart';
import '../providers/topic_providers.dart';
import '../providers/year_providers.dart';

/// Admin-only question controller — extends the base question capabilities
/// with bulk operations, CSV import/export, and question duplication.
///
/// Filter state is driven by the `adminQ*` [StateProvider]s defined in
/// [admin_question_providers.dart] so the admin screen has independent state
/// from the existing [QuestionBankScreen].
class AdminQuestionController extends AsyncNotifier<List<Question>> {
  QuestionBankService get _service =>
      ref.read(questionBankServiceProvider);

  AdminQuestionService get _adminService =>
      ref.read(adminQuestionServiceProvider);

  @override
  Future<List<Question>> build() async {
    final String subjectId = ref.watch(adminQSubjectFilterProvider);
    final String yearId = ref.watch(adminQYearFilterProvider);
    final String chapterId = ref.watch(adminQChapterFilterProvider);
    final String topicId = ref.watch(adminQTopicFilterProvider);
    final String search = ref.watch(adminQSearchQueryProvider);
    final QuestionSortOrder sortOrder = ref.watch(adminQSortOrderProvider);
    final QuestionType? typeFilter = ref.watch(adminQTypeFilterProvider);
    final QuestionDifficulty? diffFilter =
        ref.watch(adminQDifficultyFilterProvider);

    final Result<List<Question>> result = await _service.getQuestions(
      subjectId: subjectId.isEmpty ? null : subjectId,
      yearId: yearId.isEmpty ? null : yearId,
      chapterId: chapterId.isEmpty ? null : chapterId,
      topicId: topicId.isEmpty ? null : topicId,
      search: search.isEmpty ? null : search,
      sortOrder: sortOrder,
      questionType: typeFilter,
      difficulty: diffFilter,
      isActive: null, // admin sees all (active + inactive)
    );

    return result.when(
      success: (List<Question> list) => list,
      failure: (f) => throw f,
    );
  }

  /// Re-evaluates the build() function by invalidating this provider.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // ── Standard CRUD ─────────────────────────────────────────────────────────

  /// Creates a question and prepends it to the current list on success.
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
    final Result<Question> result = await _service.createQuestion(
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
      success: (Question q) {
        state = state.whenData(
          (List<Question> list) => <Question>[q, ...list],
        );
      },
      failure: (_) {},
    );

    return result;
  }

  /// Updates a question and refreshes it in the list.
  Future<Result<Question>> updateQuestion({
    required String questionId,
    required String topicId,
    required String questionText,
    required QuestionType questionType,
    required QuestionDifficulty difficulty,
    required String correctAnswer,
    required bool isActive,
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
    final Result<Question> result = await _service.updateQuestion(
      questionId: questionId,
      topicId: topicId,
      questionText: questionText,
      questionType: questionType,
      difficulty: difficulty,
      correctAnswer: correctAnswer,
      isActive: isActive,
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
      success: (Question updated) {
        state = state.whenData(
          (List<Question> list) => list
              .map((Question q) =>
                  q.questionId == questionId ? updated : q)
              .toList(),
        );
      },
      failure: (_) {},
    );

    return result;
  }

  /// Hard-deletes a question and removes it from the list.
  Future<Result<void>> deleteQuestion({required String questionId}) async {
    final Result<void> result =
        await _service.deleteQuestion(questionId: questionId);

    result.when(
      success: (_) {
        state = state.whenData(
          (List<Question> list) => list
              .where((Question q) => q.questionId != questionId)
              .toList(),
        );
      },
      failure: (_) {},
    );

    return result;
  }

  /// Flips [Question.isActive] and updates the list in place.
  Future<Result<Question>> toggleActive({
    required String questionId,
    required bool isActive,
  }) async {
    final Result<Question> result = await _service.toggleActive(
      questionId: questionId,
      isActive: isActive,
    );

    result.when(
      success: (Question updated) {
        state = state.whenData(
          (List<Question> list) => list
              .map((Question q) =>
                  q.questionId == questionId ? updated : q)
              .toList(),
        );
      },
      failure: (_) {},
    );

    return result;
  }

  // ── Admin-specific operations ─────────────────────────────────────────────

  /// Creates a duplicate of [questionId] with "(Copy)" appended to its text.
  Future<Result<Question>> duplicateQuestion({
    required String questionId,
  }) async {
    final Result<Question> result =
        await _adminService.duplicateQuestion(questionId: questionId);

    result.when(
      success: (Question copy) {
        state = state.whenData(
          (List<Question> list) {
            final int idx =
                list.indexWhere((Question q) => q.questionId == questionId);
            if (idx >= 0) {
              final List<Question> updated = List<Question>.from(list);
              updated.insert(idx + 1, copy);
              return updated;
            }
            return <Question>[copy, ...list];
          },
        );
      },
      failure: (_) {},
    );

    return result;
  }

  /// Deletes all questions in [questionIds].
  Future<Result<void>> bulkDelete({
    required Set<String> questionIds,
  }) async {
    final Result<void> result =
        await _adminService.bulkDelete(questionIds: questionIds);

    result.when(
      success: (_) {
        state = state.whenData(
          (List<Question> list) => list
              .where((Question q) => !questionIds.contains(q.questionId))
              .toList(),
        );
        ref.read(adminSelectedQuestionsProvider.notifier).state = <String>{};
        ref.read(adminBulkModeProvider.notifier).state = false;
      },
      failure: (_) {},
    );

    return result;
  }

  /// Activates or deactivates all questions in [questionIds].
  Future<Result<void>> bulkSetActive({
    required Set<String> questionIds,
    required bool isActive,
  }) async {
    final Result<void> result = await _adminService.bulkSetActive(
      questionIds: questionIds,
      isActive: isActive,
    );

    result.when(
      success: (_) {
        state = state.whenData(
          (List<Question> list) => list
              .map((Question q) => questionIds.contains(q.questionId)
                  ? q.copyWith(isActive: isActive)
                  : q)
              .toList(),
        );
        ref.read(adminSelectedQuestionsProvider.notifier).state = <String>{};
        ref.read(adminBulkModeProvider.notifier).state = false;
      },
      failure: (_) {},
    );

    return result;
  }

  /// Parses and imports [csvContent], resolving names to IDs by fetching
  /// all subjects / years / chapters / topics from their services.
  Future<AdminImportSummary> importFromCsv({
    required String csvContent,
  }) async {
    // Fetch lookup data concurrently.
    final List<dynamic> lookupResults = await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchSubjects(),
      _fetchYears(),
      _fetchChapters(),
      _fetchTopics(),
    ]);

    final List<Subject> subjects = lookupResults[0] as List<Subject>;
    final List<Year> years = lookupResults[1] as List<Year>;
    final List<Chapter> chapters = lookupResults[2] as List<Chapter>;
    final List<Topic> topics = lookupResults[3] as List<Topic>;

    final AdminImportLookups lookups = AdminImportLookups.from(
      subjects: subjects,
      years: years,
      chapters: chapters,
      topics: topics,
    );

    final AdminImportSummary summary = await _adminService.importFromCsv(
      csvContent: csvContent,
      subjectNameToId: lookups.subjectNameToId,
      yearNameToId: lookups.yearNameToId,
      chapterNameToId: lookups.chapterNameToId,
      topicNameToId: lookups.topicNameToId,
    );

    if (summary.succeeded > 0) {
      ref.invalidateSelf();
    }

    return summary;
  }

  /// Returns the current question list as a CSV string.
  String exportToCsv() {
    final List<Question> questions = state.asData?.value ?? <Question>[];
    return _adminService.exportToCsv(questions);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<Subject>> _fetchSubjects() async {
    final result = await ref.read(subjectServiceProvider).getSubjects();
    return result.when(
      success: (list) => list,
      failure: (_) => <Subject>[],
    );
  }

  Future<List<Year>> _fetchYears() async {
    final result = await ref.read(yearServiceProvider).getYears();
    return result.when(
      success: (list) => list,
      failure: (_) => <Year>[],
    );
  }

  Future<List<Chapter>> _fetchChapters() async {
    final result = await ref.read(chapterServiceProvider).getChapters();
    return result.when(
      success: (list) => list,
      failure: (_) => <Chapter>[],
    );
  }

  Future<List<Topic>> _fetchTopics() async {
    final result = await ref.read(topicServiceProvider).getTopics();
    return result.when(
      success: (list) => list,
      failure: (_) => <Topic>[],
    );
  }
}

/// Global provider for [AdminQuestionController].
final AsyncNotifierProvider<AdminQuestionController, List<Question>>
    adminQuestionControllerProvider =
    AsyncNotifierProvider<AdminQuestionController, List<Question>>(
  AdminQuestionController.new,
);
