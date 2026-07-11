import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/performance_entities.dart';
import '../../domain/entities/performance_summary.dart';
import '../../domain/repositories/performance_repository.dart';
import '../datasources/performance_remote_data_source.dart';
import '../models/performance_models.dart';
import '../services/performance_analytics_service.dart';

/// Concrete [PerformanceRepository] backed by [PerformanceRemoteDataSource]
/// and [PerformanceAnalyticsService].
///
/// The repository fetches raw `quiz_results` rows from Supabase (one request),
/// then delegates to the analytics service for all client-side aggregation.
/// This keeps the network layer thin and the analytics logic unit-testable.
class PerformanceRepositoryImpl implements PerformanceRepository {
  const PerformanceRepositoryImpl(
    this._dataSource,
    this._analytics,
  );

  final PerformanceRemoteDataSource _dataSource;
  final PerformanceAnalyticsService _analytics;

  // ── getPerformanceData ─────────────────────────────────────────────────────

  @override
  Future<Result<PerformanceData>> getPerformanceData({
    required String childId,
    PerformanceFilter? filter,
  }) async {
    try {
      final List<PerformanceRawResultModel> raw =
          await _dataSource.getRawResults(childId: childId);
      final PerformanceData data = _analytics.compute(
        childId: childId,
        raw: raw,
        filter: filter,
      );
      return Result<PerformanceData>.success(data);
    } on AppException catch (e) {
      return Result<PerformanceData>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  // ── getPerformanceSummary (backward compat) ────────────────────────────────

  @override
  Future<Result<PerformanceSummary>> getPerformanceSummary({
    required String childId,
  }) async {
    try {
      final List<PerformanceRawResultModel> raw =
          await _dataSource.getRawResults(childId: childId);
      final PerformanceSummary summary = _analytics.computeSummary(
        childId: childId,
        raw: raw,
      );
      return Result<PerformanceSummary>.success(summary);
    } on AppException catch (e) {
      return Result<PerformanceSummary>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  // ── getSessionAnswers ──────────────────────────────────────────────────────

  @override
  Future<Result<List<QuizAnswerReview>>> getSessionAnswers({
    required String sessionId,
  }) async {
    try {
      final List<QuizAnswerReviewModel> models =
          await _dataSource.getSessionAnswers(sessionId: sessionId);
      return Result<List<QuizAnswerReview>>.success(
          models.map((QuizAnswerReviewModel m) => m.toDomain()).toList());
    } on AppException catch (e) {
      return Result<List<QuizAnswerReview>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  // ── getChildrenOverviews ───────────────────────────────────────────────────

  @override
  Future<Result<List<ChildPerformanceOverview>>> getChildrenOverviews({
    required List<String> childIds,
  }) async {
    if (childIds.isEmpty) {
      return const Result<List<ChildPerformanceOverview>>.success(
          <ChildPerformanceOverview>[]);
    }
    try {
      final List<PerformanceRawResultModel> raw =
          await _dataSource.getRawResultsForChildren(childIds: childIds);

      // Group rows by child_id, then build overviews.
      // Child names are NOT stored in quiz_results; the caller (provider)
      // supplies them separately from the ChildRepository.
      final Map<String, List<PerformanceRawResultModel>> byChild =
          <String, List<PerformanceRawResultModel>>{};
      for (final String id in childIds) {
        byChild[id] = <PerformanceRawResultModel>[];
      }
      for (final PerformanceRawResultModel r in raw) {
        byChild[r.childId]?.add(r);
      }

      // Return overviews — child names resolved by provider layer.
      final List<ChildPerformanceOverview> overviews = byChild.entries
          .map((MapEntry<String, List<PerformanceRawResultModel>> e) =>
              ChildSummaryRawModel(childId: e.key, results: e.value)
                  .toOverview(e.key)) // name placeholder: provider replaces
          .toList();

      return Result<List<ChildPerformanceOverview>>.success(overviews);
    } on AppException catch (e) {
      return Result<List<ChildPerformanceOverview>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
