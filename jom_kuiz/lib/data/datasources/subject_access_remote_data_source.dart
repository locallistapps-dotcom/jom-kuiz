import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/subscription_error_codes.dart';
import '../models/subscription_models.dart';

/// API-layer client for the `parent_subject_access` Supabase PostgREST table.
///
/// RLS ensures a parent can only read/write their own access rows.
/// Admin reads all rows by using service_role via the backend.
abstract class SubjectAccessRemoteDataSource {
  Future<List<SubjectAccessModel>> getParentAccess(String parentId);
  Future<bool> checkAccess({
    required String parentId,
    required String subjectId,
  });
  Future<SubjectAccessModel> grantAccess(GrantAccessRequest request);
  Future<void> revokeAccess(String accessId);
  Future<void> revokeAccessBySubject({
    required String parentId,
    required String subjectId,
  });
  Future<List<SubjectAccessModel>> getAllAccess({String? parentId});
}

class SubjectAccessRemoteDataSourceImpl
    implements SubjectAccessRemoteDataSource {
  const SubjectAccessRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/parent_subject_access';

  @override
  Future<List<SubjectAccessModel>> getParentAccess(String parentId) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'parent_id': 'eq.$parentId',
          'order': 'granted_at.asc',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              SubjectAccessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<bool> checkAccess({
    required String parentId,
    required String subjectId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'parent_id': 'eq.$parentId',
          'subject_id': 'eq.$subjectId',
          'select': 'id,expires_at',
          'limit': '1',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) return false;
      final dynamic raw = (list.first as Map<String, dynamic>)['expires_at'];
      if (raw == null) return true;
      return DateTime.parse(raw as String).isAfter(DateTime.now());
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<SubjectAccessModel> grantAccess(GrantAccessRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _base,
        data: request.toJson(),
        options: Options(headers: <String, String>{
          'Prefer': 'return=representation,resolution=ignore-duplicates',
        }),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        // Row already existed (ON CONFLICT DO NOTHING) — fetch it instead.
        final List<SubjectAccessModel> existing =
            await getParentAccess(request.parentId);
        return existing.firstWhere((SubjectAccessModel a) =>
            a.subjectId == request.subjectId);
      }
      return SubjectAccessModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        fallbackCode: SubscriptionErrorCodes.accessOperationFailed,
      );
    }
  }

  @override
  Future<void> revokeAccess(String accessId) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$accessId'},
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubscriptionErrorCodes.accessNotFound,
        fallbackCode: SubscriptionErrorCodes.accessOperationFailed,
      );
    }
  }

  @override
  Future<void> revokeAccessBySubject({
    required String parentId,
    required String subjectId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'parent_id': 'eq.$parentId',
          'subject_id': 'eq.$subjectId',
        },
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        fallbackCode: SubscriptionErrorCodes.accessOperationFailed,
      );
    }
  }

  @override
  Future<List<SubjectAccessModel>> getAllAccess({String? parentId}) async {
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'order': 'granted_at.desc',
      };
      if (parentId != null) params['parent_id'] = 'eq.$parentId';

      final Response<dynamic> res =
          await _dio.get<dynamic>(_base, queryParameters: params);
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              SubjectAccessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Error mapping ────────────────────────────────────────────────────────────

  AppException _mapError(
    DioException e, {
    String? notFoundCode,
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
    if (status == 401 || status == 403) {
      return const UnauthorizedException('Unauthorized');
    }
    return ServerException(
        'Something went wrong',
        fallbackCode ?? SubscriptionErrorCodes.accessOperationFailed,
        e);
  }
}
