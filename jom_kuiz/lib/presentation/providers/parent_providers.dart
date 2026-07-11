import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/parent_remote_data_source.dart';
import '../../data/repositories/parent_repository_impl.dart';
import '../../data/services/parent_service.dart';
import '../../domain/repositories/parent_repository.dart';

/// Wires the Parent feature's dependency chain:
/// `Dio -> ParentRemoteDataSource -> ParentRepository -> ParentService`.
///
/// Infrastructure providers (`dioProvider`, `sessionManagerProvider`) live
/// in `core/di/providers.dart`.

final Provider<ParentRemoteDataSource> parentRemoteDataSourceProvider =
    Provider<ParentRemoteDataSource>(
  (Ref ref) => ParentRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<ParentRepository> parentRepositoryProvider = Provider<ParentRepository>(
  (Ref ref) => ParentRepositoryImpl(ref.watch(parentRemoteDataSourceProvider)),
);

final Provider<ParentService> parentServiceProvider = Provider<ParentService>(
  (Ref ref) => ParentService(
    repository: ref.watch(parentRepositoryProvider),
    sessionManager: ref.watch(sessionManagerProvider),
  ),
);
