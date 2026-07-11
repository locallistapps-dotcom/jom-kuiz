import 'package:equatable/equatable.dart';

/// Lifecycle status of a parent's subscription record.
enum ParentSubscriptionStatus {
  /// Subscription is active and within its validity period.
  active,

  /// Subscription has passed its [ParentSubscription.expiryDate].
  expired,

  /// Subscription was explicitly cancelled before expiry.
  cancelled,

  /// Created but awaiting payment confirmation (reserved for Payment module).
  pending,
}

extension ParentSubscriptionStatusX on ParentSubscriptionStatus {
  /// Parses a snake_case server value (e.g. `"active"`) to the enum.
  static ParentSubscriptionStatus fromString(String value) {
    switch (value) {
      case 'active':
        return ParentSubscriptionStatus.active;
      case 'expired':
        return ParentSubscriptionStatus.expired;
      case 'cancelled':
        return ParentSubscriptionStatus.cancelled;
      case 'pending':
      default:
        return ParentSubscriptionStatus.pending;
    }
  }

  String get displayLabel {
    switch (this) {
      case ParentSubscriptionStatus.active:
        return 'Active';
      case ParentSubscriptionStatus.expired:
        return 'Expired';
      case ParentSubscriptionStatus.cancelled:
        return 'Cancelled';
      case ParentSubscriptionStatus.pending:
        return 'Pending';
    }
  }
}

/// A parent's subscription to a [SubscriptionPackage].
///
/// One parent may hold at most one active subscription at a time; the
/// server enforces this via the `prevent_duplicate_active_subscription`
/// RPC / trigger.
class ParentSubscription extends Equatable {
  const ParentSubscription({
    required this.id,
    required this.parentId,
    required this.packageId,
    required this.startDate,
    required this.expiryDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.autoRenew = false,
  });

  final String id;
  final String parentId;
  final String packageId;
  final DateTime startDate;
  final DateTime expiryDate;
  final ParentSubscriptionStatus status;

  /// Reserved for future auto-renewal implementation.
  final bool autoRenew;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// True when status is [ParentSubscriptionStatus.active] AND the expiry
  /// date has not yet passed.
  bool get isActive =>
      status == ParentSubscriptionStatus.active &&
      expiryDate.isAfter(DateTime.now());

  /// Number of days remaining, or 0 if already expired.
  int get daysRemaining {
    final Duration remaining = expiryDate.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inDays;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        parentId,
        packageId,
        startDate,
        expiryDate,
        status,
        autoRenew,
        createdAt,
        updatedAt,
      ];
}
