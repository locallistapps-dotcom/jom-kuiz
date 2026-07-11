import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/account_management_remote_data_source.dart';
import '../../data/repositories/account_management_repository_impl.dart';
import '../../data/services/account_management_service.dart';
import '../../data/services/child_auth_service.dart';
import '../../domain/repositories/account_management_repository.dart';

/// Wires the Account Management feature's dependency chain:
/// `Dio → AccountManagementRemoteDataSource → AccountManagementRepository
///        → AccountManagementService`.
///
/// Infrastructure providers (`dioProvider`) live in `core/di/providers.dart`.

final Provider<AccountManagementRemoteDataSource>
    accountManagementDataSourceProvider =
    Provider<AccountManagementRemoteDataSource>(
  (Ref ref) =>
      AccountManagementRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<AccountManagementRepository> accountManagementRepositoryProvider =
    Provider<AccountManagementRepository>(
  (Ref ref) => AccountManagementRepositoryImpl(
      ref.watch(accountManagementDataSourceProvider)),
);

final Provider<AccountManagementService> accountManagementServiceProvider =
    Provider<AccountManagementService>(
  (Ref ref) => AccountManagementService(
      repo: ref.watch(accountManagementRepositoryProvider)),
);

final Provider<ChildAuthService> childAuthServiceProvider =
    Provider<ChildAuthService>(
  (Ref ref) => ChildAuthService(
    dataSource: ref.watch(accountManagementDataSourceProvider),
    tokenManager: ref.watch(tokenManagerProvider),
  ),
);
