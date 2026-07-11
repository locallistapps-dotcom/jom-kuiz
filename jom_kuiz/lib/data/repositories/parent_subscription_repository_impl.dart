import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/parent_subscription.dart';
import '../../domain/repositories/parent_subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../models/subscription_models.dart';

class ParentSubscriptionRepositoryImpl
    implements ParentSubscriptionRepository {
  const ParentSubscriptionRepositoryImpl(this._ds);

  final SubscriptionRemoteDataSource _ds;

  @override
  Future<Result<ParentSubscription?>> getSubscription(
      String parentId) async {
    try {
      final ParentSubscriptionModel? model =
          await _ds.getParentSubscription(parentId);
      return Result<ParentSubscription?>.success(model?.toEntity());
    } on AppException catch (e) {
      return Result<ParentSubscription?>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ParentSubscription>> createSubscription({
    required String parentId,
    required String packageId,
    required DateTime startDate,
    required DateTime expiryDate,
  }) async {
    try {
      final ParentSubscriptionModel model = await _ds.createSubscription(
        CreateSubscriptionRequest(
          parentId: parentId,
          packageId: packageId,
          startDate: startDate,
          expiryDate: expiryDate,
        ),
      );
      return Result<ParentSubscription>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<ParentSubscription>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ParentSubscription>> updateStatus({
    required String id,
    required ParentSubscriptionStatus status,
  }) async {
    try {
      final ParentSubscriptionModel model =
          await _ds.updateSubscriptionStatus(id, status.name);
      return Result<ParentSubscription>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<ParentSubscription>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<List<ParentSubscription>>> getAllSubscriptions() async {
    try {
      final List<ParentSubscriptionModel> models =
          await _ds.getAllSubscriptions();
      return Result<List<ParentSubscription>>.success(
          models.map((ParentSubscriptionModel m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<ParentSubscription>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
