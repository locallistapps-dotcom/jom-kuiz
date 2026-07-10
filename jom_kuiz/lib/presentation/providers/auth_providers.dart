import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';

/// Wires the Authentication feature's dependency chain:
/// `Dio -> AuthRemoteDataSource -> AuthRepository -> AuthService`.
///
/// Infrastructure providers (`dioProvider`, `tokenManagerProvider`,
/// `sessionManagerProvider`) live in `core/di/providers.dart`.

final Provider<AuthRemoteDataSource> authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>(
  (Ref ref) => AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final Provider<AuthService> authServiceProvider = Provider<AuthService>(
  (Ref ref) => AuthService(
    repository: ref.watch(authRepositoryProvider),
    tokenManager: ref.watch(tokenManagerProvider),
    sessionManager: ref.watch(sessionManagerProvider),
  ),
);
