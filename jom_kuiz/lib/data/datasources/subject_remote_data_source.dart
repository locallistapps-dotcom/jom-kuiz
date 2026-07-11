import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/subject_error_codes.dart';
import '../../domain/entities/subject.dart';
import '../models/subject_model.dart';

/// API-layer client for the Subject Supabase REST (PostgREST) endpoints.
///
/// All queries go through the shared [Dio] instance, which must be
/// pre-configured with the Supabase project URL and `apikey` / `Authorization`
/// headers. Paths are relative to `/rest/v1`.
///
/// No business logic lives here — this is a thin HTTP wrapper only.
abstract class SubjectRemoteDataSource {
  Future<List<SubjectModel>> getSubjects({
    String? search,
    SubjectSortOrder sortOrder,
    bool? isActive,
  });

  Future<SubjectModel> getSubjectById({required String subjectId});

  Future<SubjectModel> createSubject(CreateSubjectRequest request);

  Future<SubjectModel> updateSubject({
    required String subjectId,
    required UpdateSubjectRequest request,
  });

  Future<void> deleteSubject({required String subjectId});

  Future<SubjectModel> toggleActive({
    required String subjectId,
    required ToggleSubjectActiveRequest request,
  });
}

class SubjectRemoteDataSourceImpl implements SubjectRemoteDataSource {
  const SubjectRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/subjects';

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Converts [SubjectSortOrder] to a PostgREST `order` query param value.
  String _orderParam(SubjectSortOrder sortOrder) {
    switch (sortOrder) {
      case SubjectSortOrder.nameAsc:
        return 'subject_name.asc';
      case SubjectSortOrder.createdAtDesc:
        return 'created_at.desc';
    }
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<List<SubjectModel>> getSubjects({
    String? search,
    SubjectSortOrder sortOrder = SubjectSortOrder.nameAsc,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'select': '*',
        'order': _orderParam(sortOrder),
      };
      if (search != null && search.isNotEmpty) {
        // PostgREST ilike filter: subject_name=ilike.*query*
        params['subject_name'] = 'ilike.*$search*';
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
          .map((dynamic e) =>
              SubjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<SubjectModel> getSubjectById({required String subjectId}) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'id': 'eq.$subjectId',
          'select': '*',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Subject not found',
          SubjectErrorCodes.subjectNotFound,
        );
      }
      return SubjectModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: SubjectErrorCodes.subjectNotFound);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<SubjectModel> createSubject(CreateSubjectRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _base,
        data: request.toJson(),
        options: Options(headers: <String, String>{
          // Tell PostgREST to return the created row.
          'Prefer': 'return=representation',
        }),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return SubjectModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        validationCode: SubjectErrorCodes.invalidSubjectData,
        conflictCode: SubjectErrorCodes.duplicateSubjectName,
        fallbackCode: SubjectErrorCodes.subjectOperationFailed,
      );
    }
  }

  @override
  Future<SubjectModel> updateSubject({
    required String subjectId,
    required UpdateSubjectRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$subjectId'},
        data: request.toJson(),
        options: Options(headers: <String, String>{
          'Prefer': 'return=representation',
        }),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Subject not found',
          SubjectErrorCodes.subjectNotFound,
        );
      }
      return SubjectModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubjectErrorCodes.subjectNotFound,
        validationCode: SubjectErrorCodes.invalidSubjectData,
        conflictCode: SubjectErrorCodes.duplicateSubjectName,
        fallbackCode: SubjectErrorCodes.subjectOperationFailed,
      );
    }
  }

  @override
  Future<void> deleteSubject({required String subjectId}) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$subjectId'},
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubjectErrorCodes.subjectNotFound,
        fallbackCode: SubjectErrorCodes.subjectDeleteFailed,
      );
    }
  }

  @override
  Future<SubjectModel> toggleActive({
    required String subjectId,
    required ToggleSubjectActiveRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$subjectId'},
        data: request.toJson(),
        options: Options(headers: <String, String>{
          'Prefer': 'return=representation',
        }),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Subject not found',
          SubjectErrorCodes.subjectNotFound,
        );
      }
      return SubjectModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: SubjectErrorCodes.subjectNotFound,
        fallbackCode: SubjectErrorCodes.subjectOperationFailed,
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
      fallbackCode ?? SubjectErrorCodes.subjectOperationFailed,
      e,
    );
  }
}
