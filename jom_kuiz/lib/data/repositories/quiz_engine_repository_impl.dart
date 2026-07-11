import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/quiz_engine.dart';
import '../../domain/repositories/quiz_engine_repository.dart';
import '../datasources/quiz_engine_remote_data_source.dart';

/// Concrete [QuizEngineRepository] backed by [QuizEngineRemoteDataSource].
///
/// Converts [AppException]s into [Failure]s via [GlobalExceptionHandler].
/// Persistence is best-effort: a network failure to save the result is
/// reported back to the controller but does NOT prevent the user from
/// seeing their result — the local [QuizEngineResult] is always returned.
class QuizEngineRepositoryImpl implements QuizEngineRepository {
  const QuizEngineRepositoryImpl(this._remoteDataSource);

  final QuizEngineRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void>> saveSession({required QuizEngineSession session}) async {
    try {
      await _remoteDataSource.saveSession(session: session);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> saveAnswers({
    required String sessionId,
    required List<QuizEngineAnswer> answers,
  }) async {
    try {
      await _remoteDataSource.saveAnswers(
          sessionId: sessionId, answers: answers);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> saveResult({required QuizEngineResult result}) async {
    try {
      await _remoteDataSource.saveResult(result: result);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
