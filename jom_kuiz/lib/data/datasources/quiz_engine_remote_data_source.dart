import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/quiz_engine_error_codes.dart';
import '../../domain/entities/quiz_engine.dart';
import '../models/quiz_engine_models.dart';

/// API-layer client that persists completed Quiz Engine data to Supabase.
///
/// No reads are performed here — the Quiz Engine is driven entirely by the
/// client until the quiz is finished, at which point three tables are written
/// in sequence: quiz_sessions → quiz_answers → quiz_results.
///
/// All three writes use `Prefer: return=minimal` to avoid parsing the response
/// (we already have the data client-side).
abstract class QuizEngineRemoteDataSource {
  Future<void> saveSession({required QuizEngineSession session});

  Future<void> saveAnswers({
    required String sessionId,
    required List<QuizEngineAnswer> answers,
  });

  Future<void> saveResult({required QuizEngineResult result});
}

class QuizEngineRemoteDataSourceImpl implements QuizEngineRemoteDataSource {
  const QuizEngineRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static final Options _minimalReturn = Options(
    headers: <String, String>{'Prefer': 'return=minimal'},
  );

  @override
  Future<void> saveSession({required QuizEngineSession session}) async {
    try {
      final QuizSessionPersistModel model = QuizSessionPersistModel(
        id: session.sessionId,
        topicId: session.topicId,
        questionCount: session.totalQuestions,
        startedAt: session.startedAt,
        completedAt: DateTime.now().toUtc(),
      );
      await _dio.post<dynamic>(
        '/quiz_sessions',
        data: model.toJson(),
        options: _minimalReturn,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> saveAnswers({
    required String sessionId,
    required List<QuizEngineAnswer> answers,
  }) async {
    if (answers.isEmpty) return;
    try {
      final List<Map<String, dynamic>> payload = answers
          .map((QuizEngineAnswer a) =>
              QuizAnswerPersistModel.fromEngineAnswer(
                      sessionId: sessionId, answer: a)
                  .toJson())
          .toList();
      await _dio.post<dynamic>(
        '/quiz_answers',
        data: payload,
        options: _minimalReturn,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> saveResult({required QuizEngineResult result}) async {
    try {
      await _dio.post<dynamic>(
        '/quiz_results',
        data: QuizResultPersistModel.fromEngineResult(result).toJson(),
        options: _minimalReturn,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

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
    // Include status code and server message for easier debugging.
    final int? status = e.response?.statusCode;
    final dynamic body = e.response?.data;
    final String detail = body is Map
        ? (body['message'] as String? ?? body.toString())
        : body?.toString() ?? e.message ?? 'unknown';
    return ServerException(
      'Save failed (HTTP $status): $detail',
      QuizEngineErrorCodes.persistenceFailed,
      e,
    );
  }
}
