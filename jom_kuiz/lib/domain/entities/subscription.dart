import 'package:equatable/equatable.dart';

/// Subscription plan tier.
enum SubscriptionPlan { free, basic, premium }

/// Subscription lifecycle state.
enum SubscriptionStatus { active, expired, cancelled, pending }

/// A user's subscription to the Jom Kuiz platform.
class Subscription extends Equatable {
  const Subscription({
    required this.subscriptionId,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.priceAmount,
    this.currency = 'MYR',
  });

  final String subscriptionId;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;

  /// Recurring price in minor units (cents / sen).
  final int priceAmount;
  final String currency;

  bool get isActive => status == SubscriptionStatus.active;

  @override
  List<Object?> get props => <Object?>[
        subscriptionId,
        userId,
        plan,
        status,
        startDate,
        endDate,
        priceAmount,
        currency,
      ];
}
