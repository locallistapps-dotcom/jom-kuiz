import '../../core/utils/result.dart';
import '../entities/subscription_package.dart';

/// Contract for admin CRUD over [SubscriptionPackage] records.
abstract interface class SubscriptionPackageRepository {
  /// Returns all packages. Pass [isActive] to filter.
  Future<Result<List<SubscriptionPackage>>> getPackages({bool? isActive});

  /// Returns a single package by [id].
  Future<Result<SubscriptionPackage>> getPackageById(String id);

  /// Creates a new subscription package (admin only).
  Future<Result<SubscriptionPackage>> createPackage({
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
  });

  /// Updates an existing package (admin only).
  Future<Result<SubscriptionPackage>> updatePackage({
    required String id,
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
    required bool isActive,
  });

  /// Hard-deletes a package. Fails if there are active subscriptions.
  Future<Result<void>> deletePackage(String id);

  /// Toggles the [isActive] flag on an existing package.
  Future<Result<SubscriptionPackage>> toggleActive({
    required String id,
    required bool isActive,
  });
}
