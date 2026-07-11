import '../../core/utils/result.dart';
import '../entities/quiz_engine.dart';

/// Abstract contract for persisting Quiz Engine data to the backend.
///
/// All quiz business logic (shuffling, scoring, state machine) lives in
/// [QuizEngineController] and [QuizEngineService]. This repository is
/// responsible only for durability — it writes completed sessions, per-question
/// answers, and aggregated results to Supabase.
///
/// Reading back results is intentionally omitted here; the Performance Summary
/// module will own its own repository for historical data.
abstract interface class QuizEngineRepository {
  /// Persists a completed [QuizEngineSession] header row.
  Future<Result<void>> saveSession({required QuizEngineSession session});

  /// Bulk-inserts all [QuizEngineAnswer]s for a session.
  Future<Result<void>> saveAnswers({
    required String sessionId,
    required List<QuizEngineAnswer> answers,
  });

  /// Persists the aggregated [QuizEngineResult] row.
  Future<Result<void>> saveResult({required QuizEngineResult result});
}
