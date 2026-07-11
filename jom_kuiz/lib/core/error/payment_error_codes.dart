/// Official error codes for the ToyyibPay Payment module.
abstract final class PaymentErrorCodes {
  /// Bill creation failed (ToyyibPay returned an error).
  static const String billCreationFailed = 'PAY-001';

  /// Payment verification failed (ToyyibPay API error).
  static const String verificationFailed = 'PAY-002';

  /// The payment transaction was not found.
  static const String transactionNotFound = 'PAY-003';

  /// The bill code is invalid or does not belong to this parent.
  static const String invalidBillCode = 'PAY-004';

  /// Subscription activation failed after a successful payment.
  static const String activationFailed = 'PAY-005';

  /// A payment is already pending for this parent + package.
  static const String duplicatePendingPayment = 'PAY-006';

  /// The Edge Function returned an unexpected response shape.
  static const String malformedResponse = 'PAY-007';

  /// Generic operation failure.
  static const String paymentOperationFailed = 'PAY-008';

  /// Parent has no payment history.
  static const String noPaymentHistory = 'PAY-009';

  /// Payment expired — user did not complete within the bill's expiry window.
  static const String paymentExpired = 'PAY-010';
}
