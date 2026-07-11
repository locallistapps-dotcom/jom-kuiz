import '../../core/utils/result.dart';
import '../entities/payment_transaction.dart';
import '../entities/subscription_package.dart';

/// Abstract contract for ToyyibPay payment operations.
///
/// Implementations call the Supabase Edge Functions (which hold the
/// ToyyibPay API key) and the `payment_transactions` PostgREST table.
///
/// SECURITY: subscription activation MUST only happen server-side after
/// the Edge Function verifies the payment directly with ToyyibPay —
/// never trust a client-supplied status value.
abstract interface class PaymentRepository {
  // ── Bill creation ──────────────────────────────────────────────────────────

  /// Creates a ToyyibPay bill for [package] and returns the pending
  /// [PaymentTransaction]. The [PaymentTransaction.paymentUrl] is the URL
  /// to open in the browser.
  ///
  /// Stores a pending transaction row before calling ToyyibPay so the record
  /// exists even if the user abandons the payment.
  Future<Result<PaymentTransaction>> createBill({
    required String parentId,
    required SubscriptionPackage package,
    required String parentName,
    required String parentEmail,
  });

  // ── Status ─────────────────────────────────────────────────────────────────

  /// Fetches the latest transaction record for [billCode].
  ///
  /// Returns `null` if no record exists.
  Future<Result<PaymentTransaction?>> getTransactionByBillCode(String billCode);

  /// Asks the server to verify payment status for [billCode] with ToyyibPay.
  ///
  /// The server updates the `payment_transactions` record and — if successful
  /// — activates the subscription. Returns the updated transaction.
  Future<Result<PaymentTransaction>> verifyPayment(String billCode);

  // ── History (parent) ───────────────────────────────────────────────────────

  /// Returns the payment history for [parentId], newest first.
  Future<Result<List<PaymentTransaction>>> getParentTransactions(
      String parentId);

  // ── Admin ──────────────────────────────────────────────────────────────────

  /// Returns all transactions with optional filters.
  ///
  /// [status] — filter by status string ('pending', 'success', 'failed').
  /// [parentId] — filter by parent.
  Future<Result<List<PaymentTransaction>>> getAllTransactions({
    String? status,
    String? parentId,
  });
}
