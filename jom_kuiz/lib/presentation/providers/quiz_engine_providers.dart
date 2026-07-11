import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/quiz_engine_remote_data_source.dart';
import '../../data/repositories/quiz_engine_repository_impl.dart';
import '../../domain/repositories/quiz_engine_repository.dart';
import '../../domain/repositories/question_bank_repository.dart';
import '../providers/question_bank_providers.dart';

// ── Infrastructure DI ─────────────────────────────────────────────────────────

final Provider<QuizEngineRemoteDataSource> quizEngineRemoteDataSourceProvider =
    Provider<QuizEngineRemoteDataSource>(
  (Ref ref) => QuizEngineRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<QuizEngineRepository> quizEngineRepositoryProvider =
    Provider<QuizEngineRepository>(
  (Ref ref) => QuizEngineRepositoryImpl(
    ref.watch(quizEngineRemoteDataSourceProvider),
  ),
);

/// Exposes the [QuestionBankRepository] to the Quiz Engine controller.
/// Reuses the provider declared in question_bank_providers.dart.
final Provider<QuestionBankRepository> quizQuestionBankRepositoryProvider =
    Provider<QuestionBankRepository>(
  (Ref ref) => ref.watch(questionBankRepositoryProvider),
);

// ── Quiz Home filter state ────────────────────────────────────────────────────
//
// These are separate from the Question Bank admin filters so that the two
// screens don't interfere with each other.

/// Subject UUID selected on the Quiz Home screen.
final StateProvider<String> quizSubjectFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Year UUID selected on the Quiz Home screen.
final StateProvider<String> quizYearFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Chapter UUID selected on the Quiz Home screen.
final StateProvider<String> quizChapterFilterProvider =
    StateProvider<String>((Ref ref) => '');

/// Topic UUID selected on the Quiz Home screen (required to start a quiz).
final StateProvider<String> quizTopicFilterProvider =
    StateProvider<String>((Ref ref) => '');
