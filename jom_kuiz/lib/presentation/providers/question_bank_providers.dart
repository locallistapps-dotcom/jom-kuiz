import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/question_bank_remote_data_source.dart';
import '../../data/repositories/question_bank_repository_impl.dart';
import '../../data/services/question_bank_service.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_bank_repository.dart';

/// Wires the Question Bank feature's dependency chain:
/// `Dio → QuestionBankRemoteDataSource → QuestionBankRepository
///       → QuestionBankService`.
///
/// Cascading filter providers — changing a parent clears all children:
///
///   Subject → clears Year, Chapter, Topic
///   Year    → clears Chapter, Topic
///   Chapter → clears Topic
///   Topic   → direct topic_id filter
///
/// The cascade is enforced in the screen widget, not here, so that provider
/// state changes happen in a single frame without circular dependencies.

final Provider<QuestionBankRemoteDataSource>
    questionBankRemoteDataSourceProvider =
    Provider<QuestionBankRemoteDataSource>(
  (Ref ref) => QuestionBankRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<QuestionBankRepository> questionBankRepositoryProvider =
    Provider<QuestionBankRepository>(
  (Ref ref) => QuestionBankRepositoryImpl(
    ref.watch(questionBankRemoteDataSourceProvider),
  ),
);

final Provider<QuestionBankService> questionBankServiceProvider =
    Provider<QuestionBankService>(
  (Ref ref) => QuestionBankService(
    repository: ref.watch(questionBankRepositoryProvider),
  ),
);

// ── UI state ──────────────────────────────────────────────────────────────────

/// Search text typed in the Question Bank screen.
final StateProvider<String> questionSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// Sort order selected in the Question Bank screen.
final StateProvider<QuestionSortOrder> questionSortOrderProvider =
    StateProvider<QuestionSortOrder>(
  (Ref ref) => QuestionSortOrder.createdAtDesc,
);

// ── Cascading hierarchy filters ───────────────────────────────────────────────

/// Subject UUID filter (broadest). Changing this clears Year, Chapter, Topic.
final StateProvider<String> questionSubjectFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Year UUID filter. Changing this clears Chapter, Topic.
final StateProvider<String> questionYearFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Chapter UUID filter. Changing this clears Topic.
final StateProvider<String> questionChapterFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Topic UUID filter (narrowest — direct FK on questions.topic_id).
final StateProvider<String> questionTopicFilterProvider =
    StateProvider<String>((Ref ref) => '');

// ── Type / difficulty quick filters ──────────────────────────────────────────

/// Optional question-type quick filter (null = all types).
final StateProvider<QuestionType?> questionTypeFilterProvider =
    StateProvider<QuestionType?>((Ref ref) => null);

/// Optional difficulty quick filter (null = all difficulties).
final StateProvider<QuestionDifficulty?> questionDifficultyFilterProvider =
    StateProvider<QuestionDifficulty?>((Ref ref) => null);
