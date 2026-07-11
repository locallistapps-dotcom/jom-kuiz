import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/chapter_error_codes.dart';
import '../../domain/entities/chapter.dart';
import '../models/chapter_model.dart';

/// API-layer client for the Chapter Supabase REST (PostgREST) endpoints.
///
/// All queries go through the shared [Dio] instance pre-configured with the
/// Supabase project URL and `apikey` / `Authorization` headers.
/// Paths are relative to `/rest/v1`.
///
/// No business logic lives here — this is a thin HTTP wrapper only.
abstract class ChapterRemoteDataSource {
  Future<List<ChapterModel>> getChapters({
    String? subjectId,
    String? yearId,
    String? search,
    ChapterSortOrder sortOrder,
    bool? isActive,
  });

  Future<ChapterModel> getChapterById({required String chapterId});

  Future<ChapterModel> createChapter(CreateChapterRequest request);

  Future<ChapterModel> updateChapter({
    required String chapterId,
    required UpdateChapterRequest request,
  });

  Future<void> deleteChapter({required String chapterId});

  Future<ChapterModel> toggleActive({
    required String chapterId,
    required ToggleChapterActiveRequest request,
  });
}

class ChapterRemoteDataSourceImpl implements ChapterRemoteDataSource {
  const ChapterRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/chapters';

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _orderParam(ChapterSortOrder sortOrder) {
    switch (sortOrder) {
      case ChapterSortOrder.displayOrderAsc:
        return 'display_order.asc';
      case ChapterSortOrder.nameAsc:
        return 'chapter_name.asc';
      case ChapterSortOrder.createdAtDesc:
        return 'created_at.desc';
    }
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<List<ChapterModel>> getChapters({
    String? subjectId,
    String? yearId,
    String? search,
    ChapterSortOrder sortOrder = ChapterSortOrder.displayOrderAsc,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'select': '*',
        'order': _orderParam(sortOrder),
      };
      if (subjectId != null && subjectId.isNotEmpty) {
        params['subject_id'] = 'eq.$subjectId';
      }
      if (yearId != null && yearId.isNotEmpty) {
        params['year_id'] = 'eq.$yearId';
      }
      if (search != null && search.isNotEmpty) {
        params['chapter_name'] = 'ilike.*$search*';
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
          .map(
            (dynamic e) => ChapterModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ChapterModel> getChapterById({required String chapterId}) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'id': 'eq.$chapterId',
          'select': '*',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Chapter not found',
          ChapterErrorCodes.chapterNotFound,
        );
      }
      return ChapterModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: ChapterErrorCodes.chapterNotFound);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<ChapterModel> createChapter(CreateChapterRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _base,
        data: request.toJson(),
        options: Options(
          headers: <String, String>{'Prefer': 'return=representation'},
        ),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return ChapterModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        validationCode: ChapterErrorCodes.invalidChapterData,
        conflictCode: ChapterErrorCodes.duplicateChapterName,
        fallbackCode: ChapterErrorCodes.chapterOperationFailed,
      );
    }
  }

  @override
  Future<ChapterModel> updateChapter({
    required String chapterId,
    required UpdateChapterRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$chapterId'},
        data: request.toJson(),
        options: Options(
          headers: <String, String>{'Prefer': 'return=representation'},
        ),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Chapter not found',
          ChapterErrorCodes.chapterNotFound,
        );
      }
      return ChapterModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: ChapterErrorCodes.chapterNotFound,
        validationCode: ChapterErrorCodes.invalidChapterData,
        conflictCode: ChapterErrorCodes.duplicateChapterName,
        fallbackCode: ChapterErrorCodes.chapterOperationFailed,
      );
    }
  }

  @override
  Future<void> deleteChapter({required String chapterId}) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$chapterId'},
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: ChapterErrorCodes.chapterNotFound,
        fallbackCode: ChapterErrorCodes.chapterDeleteFailed,
      );
    }
  }

  @override
  Future<ChapterModel> toggleActive({
    required String chapterId,
    required ToggleChapterActiveRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$chapterId'},
        data: request.toJson(),
        options: Options(
          headers: <String, String>{'Prefer': 'return=representation'},
        ),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Chapter not found',
          ChapterErrorCodes.chapterNotFound,
        );
      }
      return ChapterModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: ChapterErrorCodes.chapterNotFound,
        fallbackCode: ChapterErrorCodes.chapterOperationFailed,
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
      fallbackCode ?? ChapterErrorCodes.chapterOperationFailed,
      e,
    );
  }
}
