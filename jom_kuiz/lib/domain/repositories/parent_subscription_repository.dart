import '../../core/utils/result.dart';
import '../entities/parent_subscription.dart';

/// Contract for reading and managing a parent's active subscription.
abstract interface class ParentSubscriptionRepository {
  /// Returns the most recent subscription for [parentId], or `null` if none.
  Future<Result<ParentSubscription?>> getSubscription(String parentId);

  /// Creates a new subscription record (admin / payment module entry point).
  ///
  /// The repository validates that no other [ParentSubscriptionStatus.active]
  /// record exists for this parent before inserting.
  Future<Result<ParentSubscription>> createSubscription({
    required String parentId,
    required String packageId,
    required DateTime startDate,
    required DateTime expiryDate,
  });

  /// Updates the status of an existing subscription (e.g. cancel, expire).
  Future<Result<ParentSubscription>> updateStatus({
    required String id,
    required ParentSubscriptionStatus status,
  });

  /// Returns all subscriptions — admin view.
  Future<Result<List<ParentSubscription>>> getAllSubscriptions();
}
