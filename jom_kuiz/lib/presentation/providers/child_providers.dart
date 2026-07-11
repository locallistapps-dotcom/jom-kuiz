import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/child_remote_data_source.dart';
import '../../data/repositories/child_repository_impl.dart';
import '../../data/services/child_service.dart';
import '../../domain/repositories/child_repository.dart';

/// Wires the Child feature's dependency chain:
/// `Dio → ChildRemoteDataSource → ChildRepository → ChildService`.
///
/// Infrastructure providers (`dioProvider`) live in `core/di/providers.dart`.

final Provider<ChildRemoteDataSource> childRemoteDataSourceProvider =
    Provider<ChildRemoteDataSource>(
  (Ref ref) => ChildRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<ChildRepository> childRepositoryProvider =
    Provider<ChildRepository>(
  (Ref ref) =>
      ChildRepositoryImpl(ref.watch(childRemoteDataSourceProvider)),
);

final Provider<ChildService> childServiceProvider = Provider<ChildService>(
  (Ref ref) =>
      ChildService(repository: ref.watch(childRepositoryProvider)),
);

/// Holds the ID of the child currently being viewed.
///
/// Set this provider before navigating into any child screen. All child
/// controllers react to changes automatically via [ref.watch].
final StateProvider<String> currentChildIdProvider =
    StateProvider<String>((Ref ref) => '');
