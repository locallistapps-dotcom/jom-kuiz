import '../../core/utils/result.dart';
import '../entities/subscription.dart';

/// Abstract contract for subscription management.
abstract interface class SubscriptionRepository {
  /// Returns the active subscription for [userId], or a free-tier record.
  Future<Result<Subscription>> getSubscription({required String userId});

  /// Initiates a subscription upgrade to [plan] for [userId].
  Future<Result<Subscription>> subscribe({
    required String userId,
    required SubscriptionPlan plan,
  });

  /// Cancels the active subscription for [userId].
  Future<Result<Subscription>> cancelSubscription({required String userId});
}
