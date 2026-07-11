import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/performance_error_codes.dart';
import '../models/performance_models.dart';

/// API-layer client for Performance Summary reads.
///
/// All reads are plain PostgREST `GET` requests. No writes are performed.
///
/// **Supabase schema requirements:**
/// - `quiz_results` must have a `child_id uuid` column.
/// - `quiz_sessions` must have a `child_id uuid` column.
/// - The topic hierarchy (`topics`, `chapters`, `years`, `subjects`) must exist
///   with the foreign-key chain that enables PostgREST embedding.
/// - `quiz_answers` must have `question_id` FK to `questions`.
abstract class PerformanceRemoteDataSource {
  /// Fetches all quiz_results rows for [childId], joined with the full topic
  /// hierarchy (topics → chapters → years → subjects).
  ///
  /// Results are ordered newest-first.
  Future<List<PerformanceRawResultModel>> getRawResults({
    required String childId,
  });

  /// Fetches all quiz_answers for [sessionId], joined with the questions table
  /// so the review screen can display option text, explanation, etc.
  Future<List<QuizAnswerReviewModel>> getSessionAnswers({
    required String sessionId,
  });

  /// Fetches all quiz_results rows for all [childIds] in one query.
  ///
  /// Used by the Parent View to build lightweight per-child overviews.
  Future<List<PerformanceRawResultModel>> getRawResultsForChildren({
    required List<String> childIds,
  });
}

class PerformanceRemoteDataSourceImpl implements PerformanceRemoteDataSource {
  const PerformanceRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  // ── getRawResults ──────────────────────────────────────────────────────────

  @override
  Future<List<PerformanceRawResultModel>> getRawResults({
    required String childId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/quiz_results',
        queryParameters: <String, dynamic>{
          'select':
              '*,'
              'topics!inner('
              '  topic_id,'
              '  topic_name,'
              '  chapter_id,'
              '  chapters!inner('
              '    chapter_id,'
              '    chapter_name,'
              '    year_id,'
              '    years!inner('
              '      year_id,'
              '      year_name,'
              '      subject_id,'
              '      subjects!inner('
              '        subject_id,'
              '        subject_name'
              '      )'
              '    )'
              '  )'
              ')',
          'child_id': 'eq.$childId',
          'order': 'completed_at.desc',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => PerformanceRawResultModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── getSessionAnswers ──────────────────────────────────────────────────────

  @override
  Future<List<QuizAnswerReviewModel>> getSessionAnswers({
    required String sessionId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/quiz_answers',
        queryParameters: <String, dynamic>{
          'select': '*,questions!inner(*)',
          'session_id': 'eq.$sessionId',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) =>
              QuizAnswerReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── getRawResultsForChildren ───────────────────────────────────────────────

  @override
  Future<List<PerformanceRawResultModel>> getRawResultsForChildren({
    required List<String> childIds,
  }) async {
    if (childIds.isEmpty) return <PerformanceRawResultModel>[];
    try {
      // PostgREST `in.(...)` filter
      final String inFilter = 'in.(${childIds.join(',')})';
      final Response<dynamic> res = await _dio.get<dynamic>(
        '/quiz_results',
        queryParameters: <String, dynamic>{
          'select':
              'session_id,'
              'topic_id,'
              'child_id,'
              'percentage,'
              'correct_count,'
              'wrong_count,'
              'skipped_count,'
              'total_questions,'
              'time_taken_seconds,'
              'completed_at,'
              'topics!inner('
              '  topic_id,'
              '  topic_name,'
              '  chapter_id,'
              '  chapters!inner('
              '    chapter_id,'
              '    chapter_name,'
              '    year_id,'
              '    years!inner('
              '      year_id,'
              '      year_name,'
              '      subject_id,'
              '      subjects!inner('
              '        subject_id,'
              '        subject_name'
              '      )'
              '    )'
              '  )'
              ')',
          'child_id': inFilter,
          'order': 'completed_at.desc',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>? ?? <dynamic>[];
      return list
          .map((dynamic e) => PerformanceRawResultModel.fromJson(
              e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  AppException _mapError(DioException e) {
    final bool isTransport = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;

    if (isTransport) {
      return const NetworkException(
          'Unable to reach the server. Check your connection.');
    }
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return const UnauthorizedException('Unauthorized');
    }
    return ServerException(
      'Failed to load performance data.',
      PerformanceErrorCodes.loadFailed,
      e,
    );
  }
}
