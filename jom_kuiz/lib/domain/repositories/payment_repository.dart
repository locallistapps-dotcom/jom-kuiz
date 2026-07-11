import '../../core/utils/result.dart';
import '../entities/payment.dart';

/// Abstract contract for payment operations.
abstract interface class PaymentRepository {
  /// Initiates a payment of [amount] (minor units) using [method] for [userId].
  Future<Result<Payment>> initiatePayment({
    required String userId,
    required int amount,
    required String currency,
    required PaymentMethod method,
    String? description,
  });

  /// Returns the payment history for [userId], newest first.
  Future<Result<List<Payment>>> getPaymentHistory({required String userId});

  /// Returns a single payment record by [paymentId].
  Future<Result<Payment>> getPaymentById({required String paymentId});
}
