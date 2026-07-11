import 'package:equatable/equatable.dart';

/// Payment method used for a transaction.
enum PaymentMethod { card, fpx, ewallet, points }

/// Lifecycle state of a payment.
enum PaymentStatus { pending, success, failed, refunded }

/// A payment transaction record.
class Payment extends Equatable {
  const Payment({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.createdAt,
    this.reference,
    this.description,
  });

  final String paymentId;
  final String userId;

  /// Amount in minor units (cents / sen).
  final int amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;

  /// Payment-gateway reference / transaction ID.
  final String? reference;
  final String? description;

  bool get isSuccess => status == PaymentStatus.success;

  @override
  List<Object?> get props => <Object?>[
        paymentId,
        userId,
        amount,
        currency,
        method,
        status,
        createdAt,
        reference,
        description,
      ];
}
