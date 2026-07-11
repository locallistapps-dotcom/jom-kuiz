import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/subscription_package.dart';
import '../../domain/repositories/payment_repository.dart';

/// Orchestrates ToyyibPay payment business rules.
///
/// Key invariants:
/// • Subscription activation happens ONLY server-side after the Edge Function
///   verifies the payment with ToyyibPay — never on the client's say-so.
/// • [createBill] validates input before calling the repository.
/// • [verifyPayment] is safe to call multiple times (idempotent on the server).
class PaymentService {
  const PaymentService({required PaymentRepository repo}) : _repo = repo;

  final PaymentRepository _repo;

  // ── Bill initiation ────────────────────────────────────────────────────────

  /// Creates a ToyyibPay bill for [package] on behalf of [parentId].
  ///
  /// Returns a pending [PaymentTransaction] whose [PaymentTransaction.paymentUrl]
  /// the caller should open in the device browser.
  ///
  /// Pre-condition: validates that [package] has a price > 0 and that
  /// [parentEmail] is non-empty (ToyyibPay requires a valid email).
  Future<Result<PaymentTransaction>> createBill({
    required String parentId,
    required SubscriptionPackage package,
    required String parentName,
    required String parentEmail,
  }) {
    if (parentEmail.trim().isEmpty) {
      return Future<Result<PaymentTransaction>>.value(
        const Result<PaymentTransaction>.failure(
          ValidationFailure(
              'Parent email is required to proceed to payment', 'PAY-VAL'),
        ),
      );
    }
    if (package.priceCents <= 0) {
      return Future<Result<PaymentTransaction>>.value(
        const Result<PaymentTransaction>.failure(
          ValidationFailure('This package has no price set', 'PAY-VAL'),
        ),
      );
    }
    return _repo.createBill(
      parentId: parentId,
      package: package,
      parentName: parentName.trim().isEmpty ? 'Parent' : parentName.trim(),
      parentEmail: parentEmail.trim(),
    );
  }

  // ── Status & polling ───────────────────────────────────────────────────────

  /// Polls the local database for the latest status of [billCode].
  ///
  /// This is a lightweight PostgREST call — used for periodic polling from
  /// the checkout screen. Does NOT call ToyyibPay directly.
  Future<Result<PaymentTransaction?>> pollStatus(String billCode) =>
      _repo.getTransactionByBillCode(billCode);

  /// Asks the server to verify [billCode] directly with ToyyibPay.
  ///
  /// Triggers subscription activation on the server if the payment succeeded.
  /// Safe to call multiple times.
  Future<Result<PaymentTransaction>> verifyPayment(String billCode) =>
      _repo.verifyPayment(billCode);

  // ── History ────────────────────────────────────────────────────────────────

  Future<Result<List<PaymentTransaction>>> getParentTransactions(
          String parentId) =>
      _repo.getParentTransactions(parentId);

  // ── Admin ──────────────────────────────────────────────────────────────────

  Future<Result<List<PaymentTransaction>>> getAllTransactions({
    String? status,
    String? parentId,
  }) =>
      _repo.getAllTransactions(status: status, parentId: parentId);
}
