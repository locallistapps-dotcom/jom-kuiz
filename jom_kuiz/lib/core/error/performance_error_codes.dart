/// Error codes for the Performance Summary module.
///
/// Format: PERF-NNN
abstract final class PerformanceErrorCodes {
  /// Failed to load performance data from the server.
  static const String loadFailed = 'PERF-001';

  /// The requested child account was not found or is not linked.
  static const String childNotFound = 'PERF-002';

  /// The requested quiz session was not found.
  static const String sessionNotFound = 'PERF-003';

  /// No quiz data is available for the given filters.
  static const String noDataAvailable = 'PERF-004';

  /// Generic performance operation failure.
  static const String operationFailed = 'PERF-005';
}
