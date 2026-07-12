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
/// with bulk operations, CSV import/export, question duplication, and
/// server-side pagination.
///
/// Filter state is driven by the `adminQ*` [StateProvider]s defined in
/// [admin_question_providers.dart] so the admin screen has independent state
/// from the existing [QuestionBankScreen].
///
/// Pagination:
/// - Page size is [_pageSize] (20).
/// - Each filter change resets to page 1 (via [build]).
/// - Call [loadMore] to append the next page.
/// - [hasMore] / [adminQHasMoreProvider] indicate whether another page exists.
class AdminQuestionController extends AsyncNotifier<List<Question>> {
  static const int _pageSize = 20;

  /// Current fetch offset — reset to 0 on each [build] (filter change).
  int _offset = 0;

  /// Whether more questions are available beyond the currently loaded set.
  bool _hasMore = false;

  /// Reactive getter — also reflected in [adminQHasMoreProvider].
  bool get hasMore => _hasMore;

  QuestionBankService get _service =>
      ref.read(questionBankServiceProvider);

  AdminQuestionService get _adminService =>
      ref.read(adminQuestionServiceProvider);

  @override
  Future<List<Question>> build() async {
    // Listen to own state changes to keep adminQHasMoreProvider in sync.
    ref.listenSelf((_, AsyncValue<List<Question>> next) {
      if (next is AsyncData<List<Question>>) {
        ref.read(adminQHasMoreProvider.notifier).state = _hasMore;
      }
    });

    // Watch filter providers — any change triggers a rebuild (reset to page 1).
    final String subjectId = ref.watch(adminQSubjectFilterProvider);
    final String yearId = ref.watch(adminQYearFilterProvider);
    final String chapterId = ref.watch(adminQChapterFilterProvider);
    final String topicId = ref.watch(adminQTopicFilterProvider);
    final String search = ref.watch(adminQSearchQueryProvider);
    final QuestionSortOrder sortOrder = ref.watch(adminQSortOrderProvider);
    final QuestionType? typeFilter = ref.watch(adminQTypeFilterProvider);
    final QuestionDifficulty? diffFilter =
        ref.watch(adminQDifficultyFilterProvider);

    // Reset pagination on every filter change.
    _offset = 0;
    _hasMore = false;

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
      limit: _pageSize,
      offset: 0,
    );

    return result.when(
      success: (List<Question> list) {
        _hasMore = list.length >= _pageSize;
        _offset = list.length;
        return list;
      },
      failure: (f) => throw f,
    );
  }

  /// Appends the next page of questions to the current list.
  ///
  /// No-op when [hasMore] is false or the state is not [AsyncData].
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final AsyncData<List<Question>>? data =
        state.asData;
    if (data == null) return;
    final List<Question> current = data.value;

    // Read current filter values (ref.read — don't watch inside a method).
    final String subjectId = ref.read(adminQSubjectFilterProvider);
    final String yearId = ref.read(adminQYearFilterProvider);
    final String chapterId = ref.read(adminQChapterFilterProvider);
    final String topicId = ref.read(adminQTopicFilterProvider);
    final String search = ref.read(adminQSearchQueryProvider);
    final QuestionSortOrder sortOrder = ref.read(adminQSortOrderProvider);
    final QuestionType? typeFilter = ref.read(adminQTypeFilterProvider);
    final QuestionDifficulty? diffFilter =
        ref.read(adminQDifficultyFilterProvider);

    final Result<List<Question>> result = await _service.getQuestions(
      subjectId: subjectId.isEmpty ? null : subjectId,
      yearId: yearId.isEmpty ? null : yearId,
      chapterId: chapterId.isEmpty ? null : chapterId,
      topicId: topicId.isEmpty ? null : topicId,
      search: search.isEmpty ? null : search,
      sortOrder: sortOrder,
      questionType: typeFilter,
      difficulty: diffFilter,
      isActive: null,
      limit: _pageSize,
      offset: _offset,
    );

    result.when(
      success: (List<Question> nextPage) {
        _hasMore = nextPage.length >= _pageSize;
        _offset += nextPage.length;
        ref.read(adminQHasMoreProvider.notifier).state = _hasMore;
        state = AsyncData<List<Question>>(<Question>[...current, ...nextPage]);
      },
      failure: (_) {},
    );
  }

  /// Re-evaluates build() by invalidating this provider.
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

  /// Parses and imports [jsonContent], resolving names to IDs.
  /// The JSON must be an array of objects matching [AdminQuestionService.jsonImportTemplate].
  Future<AdminImportSummary> importFromJson({
    required String jsonContent,
  }) async {
    final List<dynamic> lookupResults =
        await Future.wait<dynamic>(<Future<dynamic>>[
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

    final AdminImportSummary summary = await _adminService.importFromJson(
      jsonContent: jsonContent,
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

  /// Parses and imports [csvContent], resolving names to IDs by fetching
  /// all subjects / years / chapters / topics from their services.
  Future<AdminImportSummary> importFromCsv({
    required String csvContent,
  }) async {
    final List<dynamic> lookupResults =
        await Future.wait<dynamic>(<Future<dynamic>>[
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

  /// Returns the current question list as a human-readable CSV string.
  ///
  /// Topic/Chapter/Subject/Year UUIDs are resolved to display names so
  /// the exported CSV matches the import template format exactly.
  Future<String> exportToCsv() async {
    final List<Question> questions = state.asData?.value ?? <Question>[];
    if (questions.isEmpty) {
      return _adminService.exportToCsvWithNames(
        questions,
        topicsById: <String, Topic>{},
        chaptersById: <String, Chapter>{},
        subjectsById: <String, Subject>{},
        yearsById: <String, Year>{},
      );
    }

    final List<dynamic> results =
        await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchSubjects(),
      _fetchYears(),
      _fetchChapters(),
      _fetchTopics(),
    ]);

    final List<Subject> subjects = results[0] as List<Subject>;
    final List<Year> years = results[1] as List<Year>;
    final List<Chapter> chapters = results[2] as List<Chapter>;
    final List<Topic> topics = results[3] as List<Topic>;

    return _adminService.exportToCsvWithNames(
      questions,
      topicsById: <String, Topic>{
        for (final Topic t in topics) t.topicId: t
      },
      chaptersById: <String, Chapter>{
        for (final Chapter c in chapters) c.chapterId: c
      },
      subjectsById: <String, Subject>{
        for (final Subject s in subjects) s.subjectId: s
      },
      yearsById: <String, Year>{
        for (final Year y in years) y.yearId: y
      },
    );
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
