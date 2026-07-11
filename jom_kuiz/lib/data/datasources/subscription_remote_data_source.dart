import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/subscription_error_codes.dart';
import '../models/subscription_models.dart';

/// API-layer client for Subscription Package and Parent Subscription
/// Supabase PostgREST endpoints.
///
/// Paths are relative to `/rest/v1`. No business logic lives here.
abstract class SubscriptionRemoteDataSource {
  // ── Packages ────────────────────────────────────────────────────────────────
  Future<List<SubscriptionPackageModel>> getPackages({bool? isActive});
  Future<SubscriptionPackageModel> getPackageById(String id);
  Future<SubscriptionPackageModel> createPackage(CreatePackageRequest request);
  Future<SubscriptionPackageModel> updatePackage(
      String id, UpdatePackageRequest request);
  Future<void> deletePackage(String id);
  Future<SubscriptionPackageModel> togglePackageActive(
      String id, bool isActive);

  // ── Parent Subscriptions ────────────────────────────────────────────────────
  Future<ParentSubscriptionModel?> getParentSubscription(String parentId);
  Future<ParentSubscriptionModel> createSubscription(
      CreateSubscriptionRequest request);
  Future<ParentSubscriptionModel> updateSubscriptionStatus(
      String id, String status);
  Future<List<ParentSubscriptionModel>> getAllSubscriptions();
}

class SubscriptionRemoteDataSourceImpl
    implements SubscriptionRemoteDataSource {
  const SubscriptionRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _packages = '/subscription_packages';
  static const String _subscriptions = '/parent_subscriptions';

  // ── Packages ────────────────────────────────────────────────────────────────

  @override
  Future<List<SubscriptionPackageModel>> getPackages({bool? isActive}) async {
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'select': '*',
        'order': 'created_at.asc',
      };
      if (isActive != null) params['is_active'] = 'eq.$isActive';

      final Response<dynamic> res =
          await _dio.get<dynamic>(_packages, queryParameters: params);
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              SubscriptionPackageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<SubscriptionPackageModel> getPackageById(String id) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _packages,
        queryParameters: <String, dynamic>{
          'id': 'eq.$id',
          'select': '*',
          'limit': '1',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
            'Package not found', SubscriptionErrorCodes.packageNotFound);
      }
      return SubscriptionPackageModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: SubscriptionErrorCodes.packageNotFound);
    }
  }

  @override
  Future<SubscriptionPackageModel> createPackage(
      CreatePackageRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _packages,
        data: request.toJson(),
        options:
            Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return SubscriptionPackageModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        conflictCode: SubscriptionErrorCodes.duplicatePackageName,
        fallbackCode: SubscriptionErrorCodes.subscriptionOperationFailed,
      );
    }
  }

  @override
  Future<SubscriptionPackageModel> updatePackage(
      String id, UpdatePackageRequest request) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _packages,
        queryParameters: <String, dynamic>{'id': 'eq.$id'},
        data: request.toJson(),
        options:
            Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
            'Package not found', SubscriptionErrorCodes.packageNotFound);
      }
      return SubscriptionPackageModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubscriptionErrorCodes.packageNotFound,
        conflictCode: SubscriptionErrorCodes.duplicatePackageName,
        fallbackCode: SubscriptionErrorCodes.subscriptionOperationFailed,
      );
    }
  }

  @override
  Future<void> deletePackage(String id) async {
    try {
      await _dio.delete<dynamic>(
        _packages,
        queryParameters: <String, dynamic>{'id': 'eq.$id'},
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubscriptionErrorCodes.packageNotFound,
        conflictCode: SubscriptionErrorCodes.packageHasSubscribers,
        fallbackCode: SubscriptionErrorCodes.subscriptionOperationFailed,
      );
    }
  }

  @override
  Future<SubscriptionPackageModel> togglePackageActive(
      String id, bool isActive) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _packages,
        queryParameters: <String, dynamic>{'id': 'eq.$id'},
        data: <String, dynamic>{'is_active': isActive},
        options:
            Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
            'Package not found', SubscriptionErrorCodes.packageNotFound);
      }
      return SubscriptionPackageModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubscriptionErrorCodes.packageNotFound,
        fallbackCode: SubscriptionErrorCodes.subscriptionOperationFailed,
      );
    }
  }

  // ── Parent Subscriptions ────────────────────────────────────────────────────

  @override
  Future<ParentSubscriptionModel?> getParentSubscription(
      String parentId) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _subscriptions,
        queryParameters: <String, dynamic>{
          'parent_id': 'eq.$parentId',
          'order': 'created_at.desc',
          'limit': '1',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) return null;
      return ParentSubscriptionModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ParentSubscriptionModel> createSubscription(
      CreateSubscriptionRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _subscriptions,
        data: request.toJson(),
        options:
            Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return ParentSubscriptionModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        conflictCode: SubscriptionErrorCodes.duplicateSubscription,
        fallbackCode: SubscriptionErrorCodes.subscriptionOperationFailed,
      );
    }
  }

  @override
  Future<ParentSubscriptionModel> updateSubscriptionStatus(
      String id, String status) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _subscriptions,
        queryParameters: <String, dynamic>{'id': 'eq.$id'},
        data: <String, dynamic>{'status': status},
        options:
            Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Subscription not found',
            SubscriptionErrorCodes.subscriptionNotFound);
      }
      return ParentSubscriptionModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubscriptionErrorCodes.subscriptionNotFound,
        fallbackCode: SubscriptionErrorCodes.subscriptionOperationFailed,
      );
    }
  }

  @override
  Future<List<ParentSubscriptionModel>> getAllSubscriptions() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _subscriptions,
        queryParameters: <String, dynamic>{'order': 'created_at.desc'},
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              ParentSubscriptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Error mapping ────────────────────────────────────────────────────────────

  AppException _mapError(
    DioException e, {
    String? notFoundCode,
    String? conflictCode,
    String? fallbackCode,
  }) {
    final bool isTransport = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
    if (isTransport) {
      return const NetworkException(
          'Unable to reach the server. Check your connection.');
    }
    final int? status = e.response?.statusCode;
    if (status == 404 && notFoundCode != null) {
      return ServerException('Not found', notFoundCode, e);
    }
    if (status == 409 && conflictCode != null) {
      return ValidationException('Conflict', conflictCode, e);
    }
    if (status == 401 || status == 403) {
      return const UnauthorizedException('Unauthorized');
    }
    return ServerException(
        'Something went wrong',
        fallbackCode ?? SubscriptionErrorCodes.subscriptionOperationFailed,
        e);
  }
}
