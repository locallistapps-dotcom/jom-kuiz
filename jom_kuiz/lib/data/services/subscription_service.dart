import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/parent_subscription.dart';
import '../../domain/entities/subscription_package.dart';
import '../../domain/repositories/parent_subscription_repository.dart';
import '../../domain/repositories/subscription_package_repository.dart';

/// Orchestrates Subscription Package and Parent Subscription business rules.
///
/// Validates pre-conditions (duplicate subscription, invalid package) before
/// delegating to repositories. All public methods return [Result]<T>.
class SubscriptionService {
  const SubscriptionService({
    required SubscriptionPackageRepository packageRepo,
    required ParentSubscriptionRepository subscriptionRepo,
  })  : _packageRepo = packageRepo,
        _subscriptionRepo = subscriptionRepo;

  final SubscriptionPackageRepository _packageRepo;
  final ParentSubscriptionRepository _subscriptionRepo;

  // ── Package operations (admin) ─────────────────────────────────────────────

  Future<Result<List<SubscriptionPackage>>> getPackages({
    bool? isActive,
  }) =>
      _packageRepo.getPackages(isActive: isActive);

  Future<Result<SubscriptionPackage>> getPackageById(String id) =>
      _packageRepo.getPackageById(id);

  Future<Result<SubscriptionPackage>> createPackage({
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
  }) {
    final String? err =
        _validatePackage(name: name, priceCents: priceCents, durationDays: durationDays);
    if (err != null) {
      return Future<Result<SubscriptionPackage>>.value(
        Result<SubscriptionPackage>.failure(ValidationFailure(err, 'SUB-VAL')),
      );
    }
    return _packageRepo.createPackage(
      name: name.trim(),
      description: description?.trim(),
      maxChildren: maxChildren,
      includedSubjectIds: includedSubjectIds,
      priceCents: priceCents,
      durationDays: durationDays,
    );
  }

  Future<Result<SubscriptionPackage>> updatePackage({
    required String id,
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
    required bool isActive,
  }) {
    final String? err =
        _validatePackage(name: name, priceCents: priceCents, durationDays: durationDays);
    if (err != null) {
      return Future<Result<SubscriptionPackage>>.value(
        Result<SubscriptionPackage>.failure(ValidationFailure(err, 'SUB-VAL')),
      );
    }
    return _packageRepo.updatePackage(
      id: id,
      name: name.trim(),
      description: description?.trim(),
      maxChildren: maxChildren,
      includedSubjectIds: includedSubjectIds,
      priceCents: priceCents,
      durationDays: durationDays,
      isActive: isActive,
    );
  }

  Future<Result<void>> deletePackage(String id) =>
      _packageRepo.deletePackage(id);

  Future<Result<SubscriptionPackage>> togglePackageActive(
          String id, bool isActive) =>
      _packageRepo.toggleActive(id: id, isActive: isActive);

  // ── Parent Subscription ────────────────────────────────────────────────────

  Future<Result<ParentSubscription?>> getSubscription(String parentId) =>
      _subscriptionRepo.getSubscription(parentId);

  /// Creates an active subscription for [parentId] using [packageId].
  ///
  /// Prevents duplicate active subscriptions. The [startDate] defaults to
  /// today; [expiryDate] is computed from the package's [durationDays].
  Future<Result<ParentSubscription>> activateSubscription({
    required String parentId,
    required SubscriptionPackage package,
  }) async {
    // Guard: no existing active subscription.
    final Result<ParentSubscription?> existing =
        await _subscriptionRepo.getSubscription(parentId);
    final bool alreadyActive = existing.when(
      success: (ParentSubscription? s) => s != null && s.isActive,
      failure: (_) => false,
    );
    if (alreadyActive) {
      return const Result<ParentSubscription>.failure(
        ValidationFailure(
          'You already have an active subscription.',
          'SUB-004',
        ),
      );
    }

    final DateTime now = DateTime.now();
    final DateTime expiry = now.add(Duration(days: package.durationDays));
    return _subscriptionRepo.createSubscription(
      parentId: parentId,
      packageId: package.id,
      startDate: now,
      expiryDate: expiry,
    );
  }

  Future<Result<ParentSubscription>> cancelSubscription(String id) =>
      _subscriptionRepo.updateStatus(
          id: id, status: ParentSubscriptionStatus.cancelled);

  Future<Result<List<ParentSubscription>>> getAllSubscriptions() =>
      _subscriptionRepo.getAllSubscriptions();

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validatePackage({
    required String name,
    required int priceCents,
    required int durationDays,
  }) {
    if (name.trim().length < 2) {
      return 'Package name must be at least 2 characters';
    }
    if (priceCents < 0) return 'Price cannot be negative';
    if (durationDays < 1) return 'Duration must be at least 1 day';
    return null;
  }
}
