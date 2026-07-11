import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/year_error_codes.dart';
import '../../domain/entities/year.dart';
import '../models/year_model.dart';

/// API-layer client for the Year Supabase REST (PostgREST) endpoints.
///
/// All queries go through the shared [Dio] instance, which must be
/// pre-configured with the Supabase project URL and `apikey` / `Authorization`
/// headers. Paths are relative to `/rest/v1`.
///
/// No business logic lives here — this is a thin HTTP wrapper only.
abstract class YearRemoteDataSource {
  Future<List<YearModel>> getYears({
    String? search,
    YearSortOrder sortOrder,
    bool? isActive,
  });

  Future<YearModel> getYearById({required String yearId});

  Future<YearModel> createYear(CreateYearRequest request);

  Future<YearModel> updateYear({
    required String yearId,
    required UpdateYearRequest request,
  });

  Future<void> deleteYear({required String yearId});

  Future<YearModel> toggleActive({
    required String yearId,
    required ToggleYearActiveRequest request,
  });
}

class YearRemoteDataSourceImpl implements YearRemoteDataSource {
  const YearRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/years';

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _orderParam(YearSortOrder sortOrder) {
    switch (sortOrder) {
      case YearSortOrder.nameAsc:
        return 'year_name.asc';
      case YearSortOrder.displayOrderAsc:
        return 'display_order.asc';
      case YearSortOrder.createdAtDesc:
        return 'created_at.desc';
    }
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<List<YearModel>> getYears({
    String? search,
    YearSortOrder sortOrder = YearSortOrder.displayOrderAsc,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'select': '*',
        'order': _orderParam(sortOrder),
      };
      if (search != null && search.isNotEmpty) {
        params['year_name'] = 'ilike.*$search*';
      }
      if (isActive != null) {
        params['is_active'] = 'eq.$isActive';
      }

      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: params,
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) => YearModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<YearModel> getYearById({required String yearId}) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'id': 'eq.$yearId',
          'select': '*',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Year not found', YearErrorCodes.yearNotFound);
      }
      return YearModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: YearErrorCodes.yearNotFound);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<YearModel> createYear(CreateYearRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _base,
        data: request.toJson(),
        options: Options(headers: <String, String>{
          'Prefer': 'return=representation',
        }),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return YearModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        validationCode: YearErrorCodes.invalidYearData,
        conflictCode: YearErrorCodes.duplicateYearName,
        fallbackCode: YearErrorCodes.yearOperationFailed,
      );
    }
  }

  @override
  Future<YearModel> updateYear({
    required String yearId,
    required UpdateYearRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$yearId'},
        data: request.toJson(),
        options: Options(headers: <String, String>{
          'Prefer': 'return=representation',
        }),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Year not found', YearErrorCodes.yearNotFound);
      }
      return YearModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: YearErrorCodes.yearNotFound,
        validationCode: YearErrorCodes.invalidYearData,
        conflictCode: YearErrorCodes.duplicateYearName,
        fallbackCode: YearErrorCodes.yearOperationFailed,
      );
    }
  }

  @override
  Future<void> deleteYear({required String yearId}) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$yearId'},
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: YearErrorCodes.yearNotFound,
        fallbackCode: YearErrorCodes.yearDeleteFailed,
      );
    }
  }

  @override
  Future<YearModel> toggleActive({
    required String yearId,
    required ToggleYearActiveRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$yearId'},
        data: request.toJson(),
        options: Options(headers: <String, String>{
          'Prefer': 'return=representation',
        }),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Year not found', YearErrorCodes.yearNotFound);
      }
      return YearModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: YearErrorCodes.yearNotFound,
        fallbackCode: YearErrorCodes.yearOperationFailed,
      );
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  AppException _mapError(
    DioException e, {
    String? notFoundCode,
    String? validationCode,
    String? conflictCode,
    String? fallbackCode,
  }) {
    final bool isTransport = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;

    if (isTransport) {
      return const NetworkException(
        'Unable to reach the server. Check your connection.',
      );
    }

    final int? status = e.response?.statusCode;
    if (status == 404 && notFoundCode != null) {
      return ServerException('Resource not found', notFoundCode, e);
    }
    if (status == 409 && conflictCode != null) {
      return ValidationException('Duplicate entry', conflictCode, e);
    }
    if (status == 422 && validationCode != null) {
      return ValidationException('Validation failed', validationCode, e);
    }
    if (status == 401 || status == 403) {
      return const UnauthorizedException('Unauthorized');
    }
    return ServerException(
      'Something went wrong',
      fallbackCode ?? YearErrorCodes.yearOperationFailed,
      e,
    );
  }
}
