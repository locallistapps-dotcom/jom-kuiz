import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/performance_remote_data_source.dart';
import '../../data/repositories/performance_repository_impl.dart';
import '../../data/services/performance_analytics_service.dart';
import '../../domain/entities/performance_entities.dart';
import '../../domain/repositories/performance_repository.dart';
import '../controllers/performance_controller.dart';
import 'child_providers.dart';

// ── Infrastructure DI ─────────────────────────────────────────────────────────

final Provider<PerformanceAnalyticsService>
    performanceAnalyticsServiceProvider =
    Provider<PerformanceAnalyticsService>(
  (Ref ref) => const PerformanceAnalyticsService(),
);

final Provider<PerformanceRemoteDataSource>
    performanceRemoteDataSourceProvider =
    Provider<PerformanceRemoteDataSource>(
  (Ref ref) => PerformanceRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<PerformanceRepository> performanceRepositoryProvider =
    Provider<PerformanceRepository>(
  (Ref ref) => PerformanceRepositoryImpl(
    ref.watch(performanceRemoteDataSourceProvider),
    ref.watch(performanceAnalyticsServiceProvider),
  ),
);

// ── Active child being viewed ─────────────────────────────────────────────────

/// The child whose performance is currently being displayed.
///
/// Set this before navigating to any Performance screen:
/// - Student self-view: set to the authenticated child's ID.
/// - Parent viewing a child: set to the selected child's ID.
///
/// Defaults to the [currentChildIdProvider] value so student dashboards work
/// without an explicit set.
final StateProvider<String> currentPerformanceChildIdProvider =
    StateProvider<String>((Ref ref) => ref.watch(currentChildIdProvider));

// ── Active filter ─────────────────────────────────────────────────────────────

final StateProvider<PerformanceFilter> performanceFilterProvider =
    StateProvider<PerformanceFilter>((Ref ref) => const PerformanceFilter());

// ── Main controller ───────────────────────────────────────────────────────────

final AsyncNotifierProvider<PerformanceController, PerformanceData>
    performanceControllerProvider =
    AsyncNotifierProvider<PerformanceController, PerformanceData>(
  PerformanceController.new,
);

// ── Session answer loader (lazy — triggered on history tap) ───────────────────

final AutoDisposeFutureProviderFamily<List<QuizAnswerReview>, String>
    sessionAnswersProvider =
    FutureProvider.autoDispose.family<List<QuizAnswerReview>, String>(
  (AutoDisposeFutureProviderFamilyRef<List<QuizAnswerReview>, String> ref, String sessionId) async {
    final PerformanceRepository repo =
        ref.watch(performanceRepositoryProvider);
    final result = await repo.getSessionAnswers(sessionId: sessionId);
    return result.when(
      success: (List<QuizAnswerReview> data) => data,
      failure: (f) => throw Exception(f.message),
    );
  },
);
