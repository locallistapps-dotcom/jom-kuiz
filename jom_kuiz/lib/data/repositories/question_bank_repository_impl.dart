import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_bank_repository.dart';
import '../datasources/question_bank_remote_data_source.dart';
import '../models/question_model.dart';

/// Concrete [QuestionBankRepository] backed by [QuestionBankRemoteDataSource].
///
/// Converts [AppException]s into [Failure]s via [GlobalExceptionHandler]
/// so the presentation layer stays exception-free.
class QuestionBankRepositoryImpl implements QuestionBankRepository {
  const QuestionBankRepositoryImpl(this._remoteDataSource);

  final QuestionBankRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Question>>> getQuestions({
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
      final List<QuestionModel> models =
          await _remoteDataSource.getQuestions(
        topicId: topicId,
        chapterId: chapterId,
        subjectId: subjectId,
        yearId: yearId,
        search: search,
        questionType: questionType,
        difficulty: difficulty,
        isActive: isActive,
        sortOrder: sortOrder,
        limit: limit,
        offset: offset,
      );
      return Result<List<Question>>.success(
        models.map((QuestionModel m) => m.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Result<List<Question>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Question>> getQuestionById(
      {required String questionId}) async {
    try {
      final QuestionModel model =
          await _remoteDataSource.getQuestionById(questionId: questionId);
      return Result<Question>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Question>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<List<Question>>> getRandomQuestions({
    required String topicId,
    required int count,
  }) async {
    try {
      final List<QuestionModel> models =
          await _remoteDataSource.getRandomQuestions(
              topicId: topicId, count: count);
      return Result<List<Question>>.success(
        models.map((QuestionModel m) => m.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Result<List<Question>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Question>> createQuestion({
    required String topicId,
    required String questionText,
    required QuestionType questionType,
    required QuestionDifficulty difficulty,
    required String correctAnswer,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? explanation,
    String? explanationImageUrl,
    String? explanationVideoUrl,
    String? questionImageUrl,
    String? reference,
  }) async {
    try {
      final QuestionModel model =
          await _remoteDataSource.createQuestion(CreateQuestionRequest(
        topicId: topicId,
        questionText: questionText,
        questionType: questionType,
        difficulty: difficulty,
        correctAnswer: correctAnswer,
        optionA: optionA,
        optionB: optionB,
        optionC: optionC,
        optionD: optionD,
        explanation: explanation,
        explanationImageUrl: explanationImageUrl,
        explanationVideoUrl: explanationVideoUrl,
        questionImageUrl: questionImageUrl,
        reference: reference,
      ));
      return Result<Question>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Question>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Question>> updateQuestion({
    required String questionId,
    required String topicId,
    required String questionText,
    required QuestionType questionType,
    required QuestionDifficulty difficulty,
    required String correctAnswer,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? explanation,
    String? explanationImageUrl,
    String? explanationVideoUrl,
    String? questionImageUrl,
    String? reference,
    required bool isActive,
  }) async {
    try {
      final QuestionModel model =
          await _remoteDataSource.updateQuestion(
        questionId: questionId,
        request: UpdateQuestionRequest(
          topicId: topicId,
          questionText: questionText,
          questionType: questionType,
          difficulty: difficulty,
          correctAnswer: correctAnswer,
          optionA: optionA,
          optionB: optionB,
          optionC: optionC,
          optionD: optionD,
          explanation: explanation,
          explanationImageUrl: explanationImageUrl,
          explanationVideoUrl: explanationVideoUrl,
          questionImageUrl: questionImageUrl,
          reference: reference,
          isActive: isActive,
        ),
      );
      return Result<Question>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Question>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteQuestion({required String questionId}) async {
    try {
      await _remoteDataSource.deleteQuestion(questionId: questionId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Question>> toggleActive({
    required String questionId,
    required bool isActive,
  }) async {
    try {
      final QuestionModel model = await _remoteDataSource.toggleActive(
        questionId: questionId,
        request: ToggleQuestionActiveRequest(isActive: isActive),
      );
      return Result<Question>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Question>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
