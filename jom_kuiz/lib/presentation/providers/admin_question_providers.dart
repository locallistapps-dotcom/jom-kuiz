import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chapter.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/year.dart';
import '../../core/error/failure.dart';
import '../../data/services/admin_question_service.dart';
import 'chapter_providers.dart';
import 'question_bank_providers.dart';
import 'subject_providers.dart';
import 'topic_providers.dart';
import 'year_providers.dart';

/// Wires [AdminQuestionService] onto the existing [questionBankRepositoryProvider].
final Provider<AdminQuestionService> adminQuestionServiceProvider =
    Provider<AdminQuestionService>(
  (Ref ref) => AdminQuestionService(
    repository: ref.watch(questionBankRepositoryProvider),
  ),
);

// ── Admin question filter / sort UI state ─────────────────────────────────────
// These are intentionally separate from the main questionBank providers so the
// admin CMS screen doesn't clobber the state of other screens.

final StateProvider<String> adminQSubjectFilterProvider =
    StateProvider<String>((Ref ref) => '');

final StateProvider<String> adminQYearFilterProvider =
    StateProvider<String>((Ref ref) => '');

final StateProvider<String> adminQChapterFilterProvider =
    StateProvider<String>((Ref ref) => '');

final StateProvider<String> adminQTopicFilterProvider =
    StateProvider<String>((Ref ref) => '');

final StateProvider<String> adminQSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

final StateProvider<QuestionSortOrder> adminQSortOrderProvider =
    StateProvider<QuestionSortOrder>(
        (Ref ref) => QuestionSortOrder.createdAtDesc);

final StateProvider<QuestionType?> adminQTypeFilterProvider =
    StateProvider<QuestionType?>((Ref ref) => null);

final StateProvider<QuestionDifficulty?> adminQDifficultyFilterProvider =
    StateProvider<QuestionDifficulty?>((Ref ref) => null);

// ── Bulk-selection state ──────────────────────────────────────────────────────

/// Whether the question list is in multi-select mode.
final StateProvider<bool> adminBulkModeProvider =
    StateProvider<bool>((Ref ref) => false);

/// IDs of currently selected questions (used during bulk operations).
final StateProvider<Set<String>> adminSelectedQuestionsProvider =
    StateProvider<Set<String>>((Ref ref) => <String>{});

// ── Dropdown data (autoDispose so stale data is evicted on screen exit) ────────

/// All subjects (active + inactive) for the admin dropdown.
final AutoDisposeFutureProvider<List<Subject>> adminSubjectsDropdownProvider =
    FutureProvider.autoDispose<List<Subject>>((AutoDisposeRef<List<Subject>> ref) async {
  final result = await ref.watch(subjectServiceProvider).getSubjects();
  return result.when(
    success: (List<Subject> list) => list,
    failure: (Failure f) => throw f,
  );
});

/// All years (active + inactive) for the admin dropdown.
final AutoDisposeFutureProvider<List<Year>> adminYearsDropdownProvider =
    FutureProvider.autoDispose<List<Year>>((AutoDisposeRef<List<Year>> ref) async {
  final result = await ref.watch(yearServiceProvider).getYears();
  return result.when(
    success: (List<Year> list) => list,
    failure: (Failure f) => throw f,
  );
});

/// Chapters filtered by the currently selected subject + year for dropdowns.
final AutoDisposeFutureProviderFamily<List<Chapter>,
        ({String subjectId, String yearId})>
    adminChaptersDropdownProvider =
    FutureProvider.autoDispose.family<List<Chapter>,
        ({String subjectId, String yearId})>(
  (AutoDisposeRef<List<Chapter>> ref,
      ({String subjectId, String yearId}) arg) async {
    final result = await ref.watch(chapterServiceProvider).getChapters(
          subjectId: arg.subjectId.isEmpty ? null : arg.subjectId,
          yearId: arg.yearId.isEmpty ? null : arg.yearId,
        );
    return result.when(
      success: (List<Chapter> list) => list,
      failure: (Failure f) => throw f,
    );
  },
);

/// Topics filtered by the currently selected chapter for dropdowns.
final AutoDisposeFutureProviderFamily<List<Topic>, String>
    adminTopicsDropdownProvider =
    FutureProvider.autoDispose.family<List<Topic>, String>(
  (AutoDisposeRef<List<Topic>> ref, String chapterId) async {
    if (chapterId.isEmpty) return <Topic>[];
    final result = await ref
        .watch(topicServiceProvider)
        .getTopics(chapterId: chapterId);
    return result.when(
      success: (List<Topic> list) => list,
      failure: (Failure f) => throw f,
    );
  },
);
