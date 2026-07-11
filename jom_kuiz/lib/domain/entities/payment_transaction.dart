import 'package:equatable/equatable.dart';

/// Status lifecycle of a ToyyibPay payment transaction.
enum PaymentTransactionStatus {
  pending,
  success,
  failed,
  expired;
}

extension PaymentTransactionStatusX on PaymentTransactionStatus {
  static PaymentTransactionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'success':
        return PaymentTransactionStatus.success;
      case 'failed':
        return PaymentTransactionStatus.failed;
      case 'expired':
        return PaymentTransactionStatus.expired;
      default:
        return PaymentTransactionStatus.pending;
    }
  }

  String get displayLabel {
    switch (this) {
      case PaymentTransactionStatus.pending:
        return 'Pending';
      case PaymentTransactionStatus.success:
        return 'Paid';
      case PaymentTransactionStatus.failed:
        return 'Failed';
      case PaymentTransactionStatus.expired:
        return 'Expired';
    }
  }

  bool get isFinal =>
      this == PaymentTransactionStatus.success ||
      this == PaymentTransactionStatus.failed ||
      this == PaymentTransactionStatus.expired;
}

/// A ToyyibPay payment transaction record.
///
/// Maps 1-to-1 to the `payment_transactions` Supabase table.
/// Children are not involved in payments — this record belongs to the parent.
class PaymentTransaction extends Equatable {
  const PaymentTransaction({
    required this.id,
    required this.parentId,
    required this.packageId,
    required this.billCode,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.transactionId,
    this.paymentMethod,
    this.paidAt,
  });

  /// UUID primary key.
  final String id;

  /// The parent who initiated the payment.
  final String parentId;

  /// The subscription package being purchased.
  final String packageId;

  /// ToyyibPay bill code — used to construct the payment URL and to
  /// query transaction status from the ToyyibPay API.
  final String billCode;

  /// Transaction reference returned by ToyyibPay on successful payment.
  final String? transactionId;

  /// Amount in sen (minor units). 1000 sen = RM 10.00.
  final int amount;

  final PaymentTransactionStatus status;

  /// ToyyibPay payment channel label (e.g. "FPX - Maybank", "TnG eWallet").
  final String? paymentMethod;

  /// Set when status transitions to [PaymentTransactionStatus.success].
  final DateTime? paidAt;

  final DateTime createdAt;

  /// ToyyibPay payment page URL. Not stored in the database; computed on demand.
  String get paymentUrl => 'https://toyyibpay.com/$billCode';

  bool get isPending => status == PaymentTransactionStatus.pending;
  bool get isSuccess => status == PaymentTransactionStatus.success;
  bool get isFailed => status == PaymentTransactionStatus.failed;
  bool get isExpired => status == PaymentTransactionStatus.expired;

  @override
  List<Object?> get props => <Object?>[
        id,
        parentId,
        packageId,
        billCode,
        transactionId,
        amount,
        status,
        paymentMethod,
        paidAt,
        createdAt,
      ];
}
