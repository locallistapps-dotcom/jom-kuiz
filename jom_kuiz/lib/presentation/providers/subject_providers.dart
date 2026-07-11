import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/subject_remote_data_source.dart';
import '../../data/repositories/subject_repository_impl.dart';
import '../../data/services/subject_service.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';

/// Wires the Subject feature's dependency chain:
/// `Dio → SubjectRemoteDataSource → SubjectRepository → SubjectService`.
///
/// UI-state providers (search query, sort order) are also declared here so
/// the controller and screen always read from the same source of truth.

final Provider<SubjectRemoteDataSource> subjectRemoteDataSourceProvider =
    Provider<SubjectRemoteDataSource>(
  (Ref ref) => SubjectRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<SubjectRepository> subjectRepositoryProvider =
    Provider<SubjectRepository>(
  (Ref ref) =>
      SubjectRepositoryImpl(ref.watch(subjectRemoteDataSourceProvider)),
);

final Provider<SubjectService> subjectServiceProvider =
    Provider<SubjectService>(
  (Ref ref) =>
      SubjectService(repository: ref.watch(subjectRepositoryProvider)),
);

// ── UI state ──────────────────────────────────────────────────────────────────

/// The text currently typed in the search bar.
/// An empty string means no filter is applied.
final StateProvider<String> subjectSearchQueryProvider =
    StateProvider<String>((Ref ref) => '');

/// The sort order currently selected in the Subject screen.
final StateProvider<SubjectSortOrder> subjectSortOrderProvider =
    StateProvider<SubjectSortOrder>((Ref ref) => SubjectSortOrder.nameAsc);
