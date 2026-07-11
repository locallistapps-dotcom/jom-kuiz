import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/payment_error_codes.dart';
import '../models/payment_models.dart';

/// API-layer client for the ToyyibPay payment module.
///
/// Two distinct HTTP targets:
///   • [_restDio]       → Supabase PostgREST  (`/payment_transactions`)
///   • [_functionsDio]  → Supabase Edge Functions (`/functions/v1/*`)
///
/// The Edge Functions hold the ToyyibPay `userSecretKey`; the Flutter app
/// never sees it.
abstract class PaymentRemoteDataSource {
  Future<PaymentTransactionModel> createBill(CreateBillRequest request);
  Future<PaymentTransactionModel?> getTransactionByBillCode(String billCode);
  Future<PaymentTransactionModel> verifyPayment(String billCode);
  Future<List<PaymentTransactionModel>> getParentTransactions(String parentId);
  Future<List<PaymentTransactionModel>> getAllTransactions({
    String? status,
    String? parentId,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  const PaymentRemoteDataSourceImpl({
    required Dio restDio,
    required Dio functionsDio,
  })  : _restDio = restDio,
        _functionsDio = functionsDio;

  /// Standard PostgREST Dio — base URL: `{supabaseUrl}/rest/v1`.
  final Dio _restDio;

  /// Edge Functions Dio — base URL: `{supabaseUrl}/functions/v1`.
  final Dio _functionsDio;

  static const String _table = '/payment_transactions';

  // ── Bill creation ──────────────────────────────────────────────────────────

  @override
  Future<PaymentTransactionModel> createBill(
      CreateBillRequest request) async {
    try {
      final Response<dynamic> res = await _functionsDio.post<dynamic>(
        '/create-toyyibpay-bill',
        data: request.toJson(),
      );
      final Map<String, dynamic> body = res.data as Map<String, dynamic>;
      _assertOk(body, PaymentErrorCodes.billCreationFailed);
      return PaymentTransactionModel.fromJson(
          body['transaction'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e,
          fallbackCode: PaymentErrorCodes.billCreationFailed);
    }
  }

  // ── Verification ───────────────────────────────────────────────────────────

  @override
  Future<PaymentTransactionModel> verifyPayment(String billCode) async {
    try {
      final Response<dynamic> res = await _functionsDio.post<dynamic>(
        '/verify-toyyibpay-payment',
        data: <String, dynamic>{'bill_code': billCode},
      );
      final Map<String, dynamic> body = res.data as Map<String, dynamic>;
      _assertOk(body, PaymentErrorCodes.verificationFailed);
      return PaymentTransactionModel.fromJson(
          body['transaction'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e,
          notFoundCode: PaymentErrorCodes.invalidBillCode,
          fallbackCode: PaymentErrorCodes.verificationFailed);
    }
  }

  // ── Queries (PostgREST) ────────────────────────────────────────────────────

  @override
  Future<PaymentTransactionModel?> getTransactionByBillCode(
      String billCode) async {
    try {
      final Response<dynamic> res = await _restDio.get<dynamic>(
        _table,
        queryParameters: <String, dynamic>{
          'bill_code': 'eq.$billCode',
          'select': '*',
          'limit': '1',
          'order': 'created_at.desc',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) return null;
      return PaymentTransactionModel.fromJson(
          list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<PaymentTransactionModel>> getParentTransactions(
      String parentId) async {
    try {
      final Response<dynamic> res = await _restDio.get<dynamic>(
        _table,
        queryParameters: <String, dynamic>{
          'parent_id': 'eq.$parentId',
          'order': 'created_at.desc',
        },
      );
      return _parseList(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<PaymentTransactionModel>> getAllTransactions({
    String? status,
    String? parentId,
  }) async {
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'order': 'created_at.desc',
      };
      if (status != null) params['status'] = 'eq.$status';
      if (parentId != null) params['parent_id'] = 'eq.$parentId';

      final Response<dynamic> res =
          await _restDio.get<dynamic>(_table, queryParameters: params);
      return _parseList(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<PaymentTransactionModel> _parseList(dynamic data) {
    final List<dynamic> list = data as List<dynamic>;
    return list
        .map((dynamic e) =>
            PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Validates that the Edge Function returned `{ "ok": true, ... }`.
  void _assertOk(Map<String, dynamic> body, String fallbackCode) {
    final bool ok = body['ok'] as bool? ?? false;
    if (!ok) {
      final String msg =
          body['error'] as String? ?? 'Edge Function returned an error';
      throw ServerException(msg, fallbackCode);
    }
  }

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

    // Extract error message from Edge Function body if available.
    final dynamic body = e.response?.data;
    final String? bodyMsg = body is Map
        ? (body as Map<String, dynamic>)['error'] as String?
        : null;

    if (status == 404 && notFoundCode != null) {
      return ServerException(
          bodyMsg ?? 'Not found', notFoundCode, e);
    }
    if (status == 409 && conflictCode != null) {
      return ValidationException(
          bodyMsg ?? 'Conflict', conflictCode, e);
    }
    if (status == 401 || status == 403) {
      return const UnauthorizedException('Unauthorized');
    }
    return ServerException(
      bodyMsg ?? 'Something went wrong',
      fallbackCode ?? PaymentErrorCodes.paymentOperationFailed,
      e,
    );
  }
}
