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

/// Holds the ID of the child currently being viewed or logged-in as.
///
/// Set this before navigating into any child screen. All child
/// controllers react to changes automatically via [ref.watch].
final StateProvider<String> currentChildIdProvider =
    StateProvider<String>((Ref ref) => '');

/// Active user role: `'parent'`, `'child'`, or `''` (unauthenticated).
///
/// Set immediately after login and cleared on logout. The [RouteGuard]
/// uses this to redirect authenticated users to the correct home screen.
final StateProvider<String> userRoleProvider =
    StateProvider<String>((Ref ref) => '');

/// Whether the currently logged-in parent also has admin privileges.
///
/// Set to `true` in [AuthController.login] when the user is found in the
/// `admin_users` table, and cleared on logout.  Admin-parents keep
/// `userRoleProvider = 'parent'` so they land on the parent dashboard;
/// this flag controls the Admin CMS entry-point visibility and route access.
final StateProvider<bool> isAdminProvider =
    StateProvider<bool>((Ref ref) => false);
