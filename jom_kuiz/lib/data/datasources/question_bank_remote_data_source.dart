import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/question_bank_error_codes.dart';
import '../../domain/entities/question.dart';
import '../models/question_model.dart';

/// API-layer client for the Question Bank Supabase REST endpoints.
///
/// All queries go through the shared [Dio] instance pre-configured with the
/// Supabase project URL and `apikey` / `Authorization` headers.
/// Paths are relative to `/rest/v1`.
///
/// Filter hierarchy (most-specific wins):
///   topicId → direct `topic_id=eq.{id}`
///   chapterId only → PostgREST inner-join through topics
///   subjectId / yearId → PostgREST 2-level inner-join through topics→chapters
abstract class QuestionBankRemoteDataSource {
  Future<List<QuestionModel>> getQuestions({
    String? topicId,
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    QuestionType? questionType,
    QuestionDifficulty? difficulty,
    bool? isActive,
    QuestionSortOrder sortOrder,
    int limit,
    int offset,
  });

  Future<QuestionModel> getQuestionById({required String questionId});

  Future<List<QuestionModel>> getRandomQuestions({
    required String topicId,
    required int count,
  });

  Future<QuestionModel> createQuestion(CreateQuestionRequest request);

  Future<QuestionModel> updateQuestion({
    required String questionId,
    required UpdateQuestionRequest request,
  });

  Future<void> deleteQuestion({required String questionId});

  Future<QuestionModel> toggleActive({
    required String questionId,
    required ToggleQuestionActiveRequest request,
  });
}

class QuestionBankRemoteDataSourceImpl implements QuestionBankRemoteDataSource {
  const QuestionBankRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/questions';

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _orderParam(QuestionSortOrder sortOrder) {
    switch (sortOrder) {
      case QuestionSortOrder.createdAtDesc:
        return 'created_at.desc';
      case QuestionSortOrder.textAsc:
        return 'question_text.asc';
      case QuestionSortOrder.difficultyAsc:
        // Supabase sorts text; easy < hard < medium alphabetically,
        // so we map to a numeric proxy via a case expression at the
        // application layer. Server order defaults to created_at.
        return 'created_at.desc';
    }
  }

  bool _notEmpty(String? s) => s != null && s.isNotEmpty;

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<List<QuestionModel>> getQuestions({
    String? topicId,
    String? chapterId,
    String? subjectId,
    String? yearId,
    String? search,
    QuestionType? questionType,
    QuestionDifficulty? difficulty,
    bool? isActive,
    QuestionSortOrder sortOrder = QuestionSortOrder.createdAtDesc,
    int limit = 1000,
    int offset = 0,
  }) async {
    try {
      // Build select clause based on which hierarchy filters are in use.
      final bool needsChapterJoin = _notEmpty(chapterId) && !_notEmpty(topicId);
      final bool needsDeepJoin =
          (_notEmpty(subjectId) || _notEmpty(yearId)) && !_notEmpty(topicId);

      String selectClause = '*';
      if (needsDeepJoin) {
        selectClause =
            '*,topics!inner(chapter_id,chapters!inner(subject_id,year_id))';
      } else if (needsChapterJoin) {
        selectClause = '*,topics!inner(chapter_id)';
      }

      final Map<String, dynamic> params = <String, dynamic>{
        'select': selectClause,
        'order': _orderParam(sortOrder),
        'limit': limit,
        'offset': offset,
      };

      // Direct filters
      if (_notEmpty(topicId)) {
        params['topic_id'] = 'eq.$topicId';
      }
      if (search != null && search.isNotEmpty) {
        params['question_text'] = 'ilike.*$search*';
      }
      if (questionType != null) {
        params['question_type'] = 'eq.${questionType.toJson()}';
      }
      if (difficulty != null) {
        params['difficulty'] = 'eq.${difficulty.toJson()}';
      }
      if (isActive != null) {
        params['is_active'] = 'eq.$isActive';
      }

      // Relationship filters via PostgREST embedding
      if (needsChapterJoin) {
        params['topics.chapter_id'] = 'eq.$chapterId';
      }
      if (needsDeepJoin) {
        if (_notEmpty(subjectId)) {
          params['topics.chapters.subject_id'] = 'eq.$subjectId';
        }
        if (_notEmpty(yearId)) {
          params['topics.chapters.year_id'] = 'eq.$yearId';
        }
      }

      final Response<dynamic> res =
          await _dio.get<dynamic>(_base, queryParameters: params);
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<QuestionModel> getQuestionById({required String questionId}) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'id': 'eq.$questionId',
          'select': '*',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
            'Question not found', QuestionBankErrorCodes.questionNotFound);
      }
      return QuestionModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: QuestionBankErrorCodes.questionNotFound);
    }
  }

  @override
  Future<List<QuestionModel>> getRandomQuestions({
    required String topicId,
    required int count,
  }) async {
    try {
      // Supabase supports random ordering via `order=random()`
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'topic_id': 'eq.$topicId',
          'is_active': 'eq.true',
          'select': '*',
          'order': 'random()',
          'limit': count,
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<QuestionModel> createQuestion(CreateQuestionRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _base,
        data: request.toJson(),
        options: Options(
            headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return QuestionModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        validationCode: QuestionBankErrorCodes.invalidQuestionData,
        conflictCode: QuestionBankErrorCodes.duplicateQuestionText,
        fallbackCode: QuestionBankErrorCodes.questionOperationFailed,
      );
    }
  }

  @override
  Future<QuestionModel> updateQuestion({
    required String questionId,
    required UpdateQuestionRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$questionId'},
        data: request.toJson(),
        options: Options(
            headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
            'Question not found', QuestionBankErrorCodes.questionNotFound);
      }
      return QuestionModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: QuestionBankErrorCodes.questionNotFound,
        validationCode: QuestionBankErrorCodes.invalidQuestionData,
        conflictCode: QuestionBankErrorCodes.duplicateQuestionText,
        fallbackCode: QuestionBankErrorCodes.questionOperationFailed,
      );
    }
  }

  @override
  Future<void> deleteQuestion({required String questionId}) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$questionId'},
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: QuestionBankErrorCodes.questionNotFound,
        fallbackCode: QuestionBankErrorCodes.questionDeleteFailed,
      );
    }
  }

  @override
  Future<QuestionModel> toggleActive({
    required String questionId,
    required ToggleQuestionActiveRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$questionId'},
        data: request.toJson(),
        options: Options(
            headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
            'Question not found', QuestionBankErrorCodes.questionNotFound);
      }
      return QuestionModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: QuestionBankErrorCodes.questionNotFound,
        fallbackCode: QuestionBankErrorCodes.questionOperationFailed,
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
          'Unable to reach the server. Check your connection.');
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
      fallbackCode ?? QuestionBankErrorCodes.questionOperationFailed,
      e,
    );
  }
}
