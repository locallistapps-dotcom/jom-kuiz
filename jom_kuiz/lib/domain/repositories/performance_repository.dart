import '../../core/utils/result.dart';
import '../entities/performance_summary.dart';

/// Abstract contract for child performance analytics.
abstract interface class PerformanceRepository {
  /// Returns the aggregated performance summary for [childId].
  Future<Result<PerformanceSummary>> getPerformanceSummary({
    required String childId,
  });
}
