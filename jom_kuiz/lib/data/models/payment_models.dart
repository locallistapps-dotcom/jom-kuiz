import '../../domain/entities/payment_transaction.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PaymentTransaction DTO
// ═══════════════════════════════════════════════════════════════════════════

class PaymentTransactionModel {
  const PaymentTransactionModel({
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

  final String id;
  final String parentId;
  final String packageId;
  final String billCode;
  final String? transactionId;
  final int amount;
  final String status;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime createdAt;

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      packageId: json['package_id'] as String,
      billCode: json['bill_code'] as String,
      transactionId: json['transaction_id'] as String?,
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  PaymentTransaction toEntity() => PaymentTransaction(
        id: id,
        parentId: parentId,
        packageId: packageId,
        billCode: billCode,
        transactionId: transactionId,
        amount: amount,
        status: PaymentTransactionStatusX.fromString(status),
        paymentMethod: paymentMethod,
        paidAt: paidAt,
        createdAt: createdAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Request objects — sent to Supabase Edge Functions
// ═══════════════════════════════════════════════════════════════════════════

class CreateBillRequest {
  const CreateBillRequest({
    required this.parentId,
    required this.packageId,
    required this.amount,
    required this.parentName,
    required this.parentEmail,
    required this.packageName,
    this.packageDescription,
  });

  final String parentId;
  final String packageId;

  /// Amount in sen (minor units). 1000 sen = RM 10.00.
  final int amount;
  final String parentName;
  final String parentEmail;
  final String packageName;
  final String? packageDescription;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'parent_id': parentId,
        'package_id': packageId,
        'amount': amount,
        'parent_name': parentName,
        'parent_email': parentEmail,
        'package_name': packageName,
        if (packageDescription != null)
          'package_description': packageDescription,
      };
}

class VerifyPaymentRequest {
  const VerifyPaymentRequest({required this.billCode});
  final String billCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bill_code': billCode,
      };
}
