import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/subscription_remote_data_source.dart';
import '../../data/repositories/parent_subscription_repository_impl.dart';
import '../../data/repositories/subscription_package_repository_impl.dart';
import '../../data/services/subscription_service.dart';
import '../../domain/repositories/parent_subscription_repository.dart';
import '../../domain/repositories/subscription_package_repository.dart';

/// Wires the Subscription feature's dependency chain:
///
/// ```
/// Dio
///  └─ SubscriptionRemoteDataSource
///       ├─ SubscriptionPackageRepository  ──┐
///       └─ ParentSubscriptionRepository  ──┤
///                                           └─ SubscriptionService
/// ```

final Provider<SubscriptionRemoteDataSource>
    subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>(
  (Ref ref) => SubscriptionRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<SubscriptionPackageRepository>
    subscriptionPackageRepositoryProvider =
    Provider<SubscriptionPackageRepository>(
  (Ref ref) => SubscriptionPackageRepositoryImpl(
      ref.watch(subscriptionRemoteDataSourceProvider)),
);

final Provider<ParentSubscriptionRepository>
    parentSubscriptionRepositoryProvider =
    Provider<ParentSubscriptionRepository>(
  (Ref ref) => ParentSubscriptionRepositoryImpl(
      ref.watch(subscriptionRemoteDataSourceProvider)),
);

final Provider<SubscriptionService> subscriptionServiceProvider =
    Provider<SubscriptionService>(
  (Ref ref) => SubscriptionService(
    packageRepo: ref.watch(subscriptionPackageRepositoryProvider),
    subscriptionRepo: ref.watch(parentSubscriptionRepositoryProvider),
  ),
);
