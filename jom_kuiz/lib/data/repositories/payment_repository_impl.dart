import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/subscription_package.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';
import '../models/payment_models.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._ds);

  final PaymentRemoteDataSource _ds;

  @override
  Future<Result<PaymentTransaction>> createBill({
    required String parentId,
    required SubscriptionPackage package,
    required String parentName,
    required String parentEmail,
  }) async {
    try {
      final PaymentTransactionModel model = await _ds.createBill(
        CreateBillRequest(
          parentId: parentId,
          packageId: package.id,
          amount: package.priceCents,
          parentName: parentName,
          parentEmail: parentEmail,
          packageName: package.name,
          packageDescription: package.description,
        ),
      );
      return Result<PaymentTransaction>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<PaymentTransaction>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<PaymentTransaction?>> getTransactionByBillCode(
      String billCode) async {
    try {
      final PaymentTransactionModel? model =
          await _ds.getTransactionByBillCode(billCode);
      return Result<PaymentTransaction?>.success(model?.toEntity());
    } on AppException catch (e) {
      return Result<PaymentTransaction?>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<PaymentTransaction>> verifyPayment(String billCode) async {
    try {
      final PaymentTransactionModel model =
          await _ds.verifyPayment(billCode);
      return Result<PaymentTransaction>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<PaymentTransaction>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<List<PaymentTransaction>>> getParentTransactions(
      String parentId) async {
    try {
      final List<PaymentTransactionModel> models =
          await _ds.getParentTransactions(parentId);
      return Result<List<PaymentTransaction>>.success(
          models.map((PaymentTransactionModel m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<PaymentTransaction>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<List<PaymentTransaction>>> getAllTransactions({
    String? status,
    String? parentId,
  }) async {
    try {
      final List<PaymentTransactionModel> models =
          await _ds.getAllTransactions(status: status, parentId: parentId);
      return Result<List<PaymentTransaction>>.success(
          models.map((PaymentTransactionModel m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<PaymentTransaction>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
