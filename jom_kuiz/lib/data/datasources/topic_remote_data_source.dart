import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/topic_error_codes.dart';
import '../../domain/entities/topic.dart';
import '../models/topic_model.dart';

/// API-layer client for the Topic Supabase REST (PostgREST) endpoints.
///
/// All queries go through the shared [Dio] instance pre-configured with the
/// Supabase project URL and `apikey` / `Authorization` headers.
/// Paths are relative to `/rest/v1`.
///
/// Server-side Subject/Year filtering uses PostgREST resource embedding:
///   topics?select=*,chapters!inner(subject_id,year_id)
///   &chapters.subject_id=eq.{subjectId}&chapters.year_id=eq.{yearId}
///
/// No business logic lives here — this is a thin HTTP wrapper only.
abstract class TopicRemoteDataSource {
  Future<List<TopicModel>> getTopics({
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    TopicSortOrder sortOrder,
    bool? isActive,
  });

  Future<TopicModel> getTopicById({required String topicId});

  Future<TopicModel> createTopic(CreateTopicRequest request);

  Future<TopicModel> updateTopic({
    required String topicId,
    required UpdateTopicRequest request,
  });

  Future<void> deleteTopic({required String topicId});

  Future<TopicModel> toggleActive({
    required String topicId,
    required ToggleTopicActiveRequest request,
  });
}

class TopicRemoteDataSourceImpl implements TopicRemoteDataSource {
  const TopicRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/topics';

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _orderParam(TopicSortOrder sortOrder) {
    switch (sortOrder) {
      case TopicSortOrder.displayOrderAsc:
        return 'display_order.asc';
      case TopicSortOrder.nameAsc:
        return 'topic_name.asc';
      case TopicSortOrder.createdAtDesc:
        return 'created_at.desc';
    }
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<List<TopicModel>> getTopics({
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    TopicSortOrder sortOrder = TopicSortOrder.displayOrderAsc,
    bool? isActive,
  }) async {
    try {
      final bool hasRelationFilter =
          (subjectId != null && subjectId.isNotEmpty) ||
              (yearId != null && yearId.isNotEmpty);

      // When filtering by subject or year, embed the chapters table so
      // PostgREST can filter on the parent's FK columns.
      final String selectClause = hasRelationFilter
          ? '*,chapters!inner(subject_id,year_id)'
          : '*';

      final Map<String, dynamic> params = <String, dynamic>{
        'select': selectClause,
        'order': _orderParam(sortOrder),
      };

      if (chapterId != null && chapterId.isNotEmpty) {
        params['chapter_id'] = 'eq.$chapterId';
      }
      if (subjectId != null && subjectId.isNotEmpty) {
        params['chapters.subject_id'] = 'eq.$subjectId';
      }
      if (yearId != null && yearId.isNotEmpty) {
        params['chapters.year_id'] = 'eq.$yearId';
      }
      if (search != null && search.isNotEmpty) {
        params['topic_name'] = 'ilike.*$search*';
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
            (dynamic e) => TopicModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<TopicModel> getTopicById({required String topicId}) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'id': 'eq.$topicId',
          'select': '*',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Topic not found',
          TopicErrorCodes.topicNotFound,
        );
      }
      return TopicModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: TopicErrorCodes.topicNotFound);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<TopicModel> createTopic(CreateTopicRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _base,
        data: request.toJson(),
        options: Options(
          headers: <String, String>{'Prefer': 'return=representation'},
        ),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return TopicModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        validationCode: TopicErrorCodes.invalidTopicData,
        conflictCode: TopicErrorCodes.duplicateTopicName,
        fallbackCode: TopicErrorCodes.topicOperationFailed,
      );
    }
  }

  @override
  Future<TopicModel> updateTopic({
    required String topicId,
    required UpdateTopicRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$topicId'},
        data: request.toJson(),
        options: Options(
          headers: <String, String>{'Prefer': 'return=representation'},
        ),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Topic not found',
          TopicErrorCodes.topicNotFound,
        );
      }
      return TopicModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: TopicErrorCodes.topicNotFound,
        validationCode: TopicErrorCodes.invalidTopicData,
        conflictCode: TopicErrorCodes.duplicateTopicName,
        fallbackCode: TopicErrorCodes.topicOperationFailed,
      );
    }
  }

  @override
  Future<void> deleteTopic({required String topicId}) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$topicId'},
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: TopicErrorCodes.topicNotFound,
        fallbackCode: TopicErrorCodes.topicDeleteFailed,
      );
    }
  }

  @override
  Future<TopicModel> toggleActive({
    required String topicId,
    required ToggleTopicActiveRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$topicId'},
        data: request.toJson(),
        options: Options(
          headers: <String, String>{'Prefer': 'return=representation'},
        ),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
          'Topic not found',
          TopicErrorCodes.topicNotFound,
        );
      }
      return TopicModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: TopicErrorCodes.topicNotFound,
        fallbackCode: TopicErrorCodes.topicOperationFailed,
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
    final String realMessage = _extractPostgrestMessage(e);

    if (status == 404 && notFoundCode != null) {
      return ServerException(realMessage, notFoundCode, e);
    }
    if (status == 409 && conflictCode != null) {
      return ValidationException(realMessage, conflictCode, e);
    }
    if (status == 422 && validationCode != null) {
      return ValidationException(realMessage, validationCode, e);
    }
    if (status == 401 || status == 403) {
      return const UnauthorizedException('Unauthorized');
    }
    return ServerException(
      realMessage,
      fallbackCode ?? TopicErrorCodes.topicOperationFailed,
      e,
    );
  }

  /// Extracts the real PostgreSQL / PostgREST error text from the Dio response
  /// body. PostgREST wraps errors as JSON with `message`, `details`, and
  /// `hint` fields. Falls back to the Dio message when the body is absent or
  /// cannot be decoded.
  static String _extractPostgrestMessage(DioException e) {
    try {
      final dynamic data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final String msg = (data['message'] as String? ?? '').trim();
        final String details = (data['details'] as String? ?? '').trim();
        final String hint = (data['hint'] as String? ?? '').trim();
        final StringBuffer buf = StringBuffer();
        if (msg.isNotEmpty) buf.write(msg);
        if (details.isNotEmpty) {
          if (buf.isNotEmpty) buf.write(' — ');
          buf.write(details);
        }
        if (hint.isNotEmpty) {
          if (buf.isNotEmpty) buf.write(' (hint: ');
          buf.write(hint);
          buf.write(')');
        }
        if (buf.isNotEmpty) return buf.toString();
      }
    } catch (_) {}
    return e.message ?? 'Something went wrong';
  }
}
