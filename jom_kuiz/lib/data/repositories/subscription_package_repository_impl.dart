import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/subscription_package.dart';
import '../../domain/repositories/subscription_package_repository.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../models/subscription_models.dart';

class SubscriptionPackageRepositoryImpl
    implements SubscriptionPackageRepository {
  const SubscriptionPackageRepositoryImpl(this._ds);

  final SubscriptionRemoteDataSource _ds;

  @override
  Future<Result<List<SubscriptionPackage>>> getPackages(
      {bool? isActive}) async {
    try {
      final List<SubscriptionPackageModel> models =
          await _ds.getPackages(isActive: isActive);
      return Result<List<SubscriptionPackage>>.success(
          models.map((SubscriptionPackageModel m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Result<List<SubscriptionPackage>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<SubscriptionPackage>> getPackageById(String id) async {
    try {
      return Result<SubscriptionPackage>.success(
          (await _ds.getPackageById(id)).toEntity());
    } on AppException catch (e) {
      return Result<SubscriptionPackage>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<SubscriptionPackage>> createPackage({
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
  }) async {
    try {
      final SubscriptionPackageModel model = await _ds.createPackage(
        CreatePackageRequest(
          name: name,
          description: description,
          maxChildren: maxChildren,
          includedSubjectIds: includedSubjectIds,
          priceCents: priceCents,
          durationDays: durationDays,
        ),
      );
      return Result<SubscriptionPackage>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<SubscriptionPackage>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<SubscriptionPackage>> updatePackage({
    required String id,
    required String name,
    String? description,
    required int maxChildren,
    required List<String> includedSubjectIds,
    required int priceCents,
    required int durationDays,
    required bool isActive,
  }) async {
    try {
      final SubscriptionPackageModel model = await _ds.updatePackage(
        id,
        UpdatePackageRequest(
          name: name,
          description: description,
          maxChildren: maxChildren,
          includedSubjectIds: includedSubjectIds,
          priceCents: priceCents,
          durationDays: durationDays,
          isActive: isActive,
        ),
      );
      return Result<SubscriptionPackage>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<SubscriptionPackage>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deletePackage(String id) async {
    try {
      await _ds.deletePackage(id);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<SubscriptionPackage>> toggleActive({
    required String id,
    required bool isActive,
  }) async {
    try {
      return Result<SubscriptionPackage>.success(
          (await _ds.togglePackageActive(id, isActive)).toEntity());
    } on AppException catch (e) {
      return Result<SubscriptionPackage>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
