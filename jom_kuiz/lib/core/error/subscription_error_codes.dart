/// Official error codes for the Subscription & Subject Access module.
abstract final class SubscriptionErrorCodes {
  /// Package with the given ID was not found.
  static const String packageNotFound = 'SUB-001';

  /// Package name is already in use.
  static const String duplicatePackageName = 'SUB-002';

  /// Package cannot be deleted because it has active subscribers.
  static const String packageHasSubscribers = 'SUB-003';

  /// The parent already has an active subscription.
  static const String duplicateSubscription = 'SUB-004';

  /// Subscription record was not found.
  static const String subscriptionNotFound = 'SUB-005';

  /// The subject access record was not found.
  static const String accessNotFound = 'SUB-006';

  /// The subject access record already exists (UNIQUE violation).
  static const String duplicateAccess = 'SUB-007';

  /// Generic operation failure for subscription operations.
  static const String subscriptionOperationFailed = 'SUB-008';

  /// Generic operation failure for subject access operations.
  static const String accessOperationFailed = 'SUB-009';

  /// The parent does not have access to the requested subject.
  static const String subjectLocked = 'SUB-010';
}
