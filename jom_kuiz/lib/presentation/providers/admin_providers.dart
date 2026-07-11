import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';

/// Wires the Admin CMS dependency chain:
/// `Dio → AdminRemoteDataSource → AdminRepository`
///
/// The [adminQuestionServiceProvider] is declared in
/// `admin_question_providers.dart` because it sits on top of the Question Bank
/// DI chain rather than the Admin chain.

final Provider<AdminRemoteDataSource> adminRemoteDataSourceProvider =
    Provider<AdminRemoteDataSource>(
  (Ref ref) => AdminRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<AdminRepository> adminRepositoryProvider =
    Provider<AdminRepository>(
  (Ref ref) =>
      AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider)),
);
