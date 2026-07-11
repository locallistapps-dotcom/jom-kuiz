import '../../core/utils/result.dart';
import '../entities/performance_entities.dart';
import '../entities/performance_summary.dart';

/// Abstract contract for all performance analytics reads.
///
/// Concrete implementation: [PerformanceRepositoryImpl].
///
/// Design notes:
/// - [getPerformanceData] returns a [PerformanceData] object that covers ALL
///   analytics views (summary, subjects, chapters, topics, history, suggestions)
///   from a **single Supabase query** so UI drill-downs require no additional
///   network calls.
/// - [getPerformanceSummary] is kept for backward compatibility and is
///   implemented as a thin wrapper around [getPerformanceData].
/// - [getSessionAnswers] is the only read that triggers a second query — it is
///   called lazily only when a user taps "Review Answers" in the history list.
abstract interface class PerformanceRepository {
  /// Loads all quiz results for [childId] and computes the full analytics set.
  ///
  /// Pass [filter] to narrow the history/topic/chapter/subject breakdowns.
  Future<Result<PerformanceData>> getPerformanceData({
    required String childId,
    PerformanceFilter? filter,
  });

  /// Returns the top-level summary (backward-compatible method).
  ///
  /// Delegates to [getPerformanceData] internally.
  Future<Result<PerformanceSummary>> getPerformanceSummary({
    required String childId,
  });

  /// Returns all answers for a specific quiz session, used for history review.
  Future<Result<List<QuizAnswerReview>>> getSessionAnswers({
    required String sessionId,
  });

  /// Returns performance overviews for the supplied [childIds].
  ///
  /// Used by the parent view to populate the children list without loading
  /// the full [PerformanceData] for every child upfront.
  Future<Result<List<ChildPerformanceOverview>>> getChildrenOverviews({
    required List<String> childIds,
  });
}
