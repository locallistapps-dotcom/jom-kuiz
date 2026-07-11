import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/performance_entities.dart';
import '../../domain/repositories/performance_repository.dart';
import '../providers/performance_providers.dart';

/// Drives all Performance Summary screens.
///
/// State machine: [AsyncValue<PerformanceData>]
/// - loading  → fetching from Supabase
/// - data     → analytics ready
/// - error    → network/server failure
///
/// The controller reloads automatically whenever [currentPerformanceChildIdProvider]
/// or [performanceFilterProvider] changes, so screens never call load() manually.
class PerformanceController extends AsyncNotifier<PerformanceData> {
  @override
  Future<PerformanceData> build() async {
    final String childId =
        ref.watch(currentPerformanceChildIdProvider);
    final PerformanceFilter filter =
        ref.watch(performanceFilterProvider);

    if (childId.isEmpty) {
      return PerformanceData.empty('');
    }

    final PerformanceRepository repo =
        ref.read(performanceRepositoryProvider);

    final result = await repo.getPerformanceData(
      childId: childId,
      filter: filter.hasAnyFilter ? filter : null,
    );

    return result.when(
      success: (PerformanceData data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  /// Resets the active filter back to "show all".
  void clearFilter() {
    ref.read(performanceFilterProvider.notifier).state =
        const PerformanceFilter();
  }

  /// Applies a new filter; the [build] method re-runs automatically.
  void applyFilter(PerformanceFilter filter) {
    ref.read(performanceFilterProvider.notifier).state = filter;
  }

  /// Hard-refreshes data (e.g. pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncValue<PerformanceData>.loading();
    state = await AsyncValue.guard(() => build());
  }
}
