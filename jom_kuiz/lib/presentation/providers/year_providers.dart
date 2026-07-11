import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/year_remote_data_source.dart';
import '../../data/repositories/year_repository_impl.dart';
import '../../data/services/year_service.dart';
import '../../domain/entities/year.dart';
import '../../domain/repositories/year_repository.dart';

/// Wires the Year feature's dependency chain:
/// `Dio → YearRemoteDataSource → YearRepository → YearService`.
///
/// UI-state providers (search query, sort order) are also declared here so
/// the controller and screen always read from the same source of truth.

final Provider<YearRemoteDataSource> yearRemoteDataSourceProvider =
    Provider<YearRemoteDataSource>(
  (Ref ref) => YearRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<YearRepository> yearRepositoryProvider =
    Provider<YearRepository>(
  (Ref ref) => YearRepositoryImpl(ref.watch(yearRemoteDataSourceProvider)),
);

final Provider<YearService> yearServiceProvider = Provider<YearService>(
  (Ref ref) => YearService(repository: ref.watch(yearRepositoryProvider)),
);

// ── UI state ──────────────────────────────────────────────────────────────────

/// The text currently typed in the search bar.
/// An empty string means no filter is applied.
final StateProvider<String> yearSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// The sort order currently selected in the Year screen.
final StateProvider<YearSortOrder> yearSortOrderProvider =
    StateProvider<YearSortOrder>((Ref ref) => YearSortOrder.displayOrderAsc);
