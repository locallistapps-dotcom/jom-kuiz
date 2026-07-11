import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../data/models/account_management_models.dart';
import '../../data/models/performance_models.dart';
import '../../data/datasources/performance_remote_data_source.dart';
import '../providers/account_management_providers.dart';
import '../providers/performance_providers.dart';

/// Loads all children for the authenticated parent, enriched with aggregated
/// quiz-performance data pulled in a single bulk query.
///
/// State: `AsyncValue<List<ChildCardData>>` — loading / error / populated list.
final AsyncNotifierProvider<ChildrenListController, List<ChildCardData>>
    childrenListControllerProvider =
    AsyncNotifierProvider<ChildrenListController, List<ChildCardData>>(
        ChildrenListController.new);

class ChildrenListController extends AsyncNotifier<List<ChildCardData>> {
  @override
  Future<List<ChildCardData>> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<ChildCardData>>.loading();
    state = await AsyncValue.guard(_load);
  }

  // ── Private ──────────────────────────────────────────────────────────────

  Future<List<ChildCardData>> _load() async {
    final Result<List<ChildManagementModel>> childResult =
        await ref.read(accountManagementServiceProvider).getChildren();

    return childResult.when(
      success: (List<ChildManagementModel> children) async {
        if (children.isEmpty) return <ChildCardData>[];

        // Bulk-fetch performance for all children in a single query.
        final List<String> childIds =
            children.map((ChildManagementModel c) => c.id).toList();

        List<PerformanceRawResultModel> allResults = <PerformanceRawResultModel>[];
        try {
          allResults = await ref
              .read(performanceRemoteDataSourceProvider)
              .getRawResultsForChildren(childIds: childIds);
        } catch (_) {
          // Performance data is best-effort: show children even if it fails.
        }

        // Group results by child_id.
        final Map<String, List<PerformanceRawResultModel>> byChild =
            <String, List<PerformanceRawResultModel>>{};
        for (final PerformanceRawResultModel r in allResults) {
          byChild.putIfAbsent(r.childId ?? '', () => <PerformanceRawResultModel>[]).add(r);
        }

        return children.map((ChildManagementModel model) {
          final List<PerformanceRawResultModel> results =
              byChild[model.id] ?? <PerformanceRawResultModel>[];
          final int total = results.length;
          final double avg = total == 0
              ? 0.0
              : results.fold<double>(
                      0, (double s, PerformanceRawResultModel r) => s + r.percentage) /
                  total;
          final double latest = results.isEmpty ? -1.0 : results.first.percentage;
          return ChildCardData.fromModel(
            model,
            totalQuizzes: total,
            averageScore: avg,
            latestScore: latest,
          );
        }).toList();
      },
      failure: (Failure f) => throw f,
    );
  }
}
