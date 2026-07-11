import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/subject_access_remote_data_source.dart';
import '../../data/repositories/subject_access_repository_impl.dart';
import '../../data/services/subject_access_service.dart';
import '../../domain/repositories/subject_access_repository.dart';

/// Wires the Subject Access feature's dependency chain:
///
/// ```
/// Dio
///  └─ SubjectAccessRemoteDataSource
///       └─ SubjectAccessRepository
///            └─ SubjectAccessService
/// ```

final Provider<SubjectAccessRemoteDataSource>
    subjectAccessRemoteDataSourceProvider =
    Provider<SubjectAccessRemoteDataSource>(
  (Ref ref) =>
      SubjectAccessRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<SubjectAccessRepository> subjectAccessRepositoryProvider =
    Provider<SubjectAccessRepository>(
  (Ref ref) => SubjectAccessRepositoryImpl(
      ref.watch(subjectAccessRemoteDataSourceProvider)),
);

final Provider<SubjectAccessService> subjectAccessServiceProvider =
    Provider<SubjectAccessService>(
  (Ref ref) => SubjectAccessService(
      repo: ref.watch(subjectAccessRepositoryProvider)),
);
