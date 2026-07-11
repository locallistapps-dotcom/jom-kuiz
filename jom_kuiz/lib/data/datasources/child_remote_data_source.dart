import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/child_error_codes.dart';
import '../models/achievement_model.dart';
import '../models/child_profile_model.dart';
import '../models/child_requests.dart';
import '../models/homework_model.dart';
import '../models/quiz_model.dart';

/// API-layer client for the Child REST endpoints.
///
/// Every method issues a real HTTP call through the shared [Dio] instance.
/// No backend logic lives here — calls will fail until the Child API is
/// implemented on the server.
abstract class ChildRemoteDataSource {
  Future<ChildProfileModel> getProfile({required String childId});
  Future<ChildProfileModel> updateProfile({
    required String childId,
    required UpdateChildProfileRequest request,
  });
  Future<ChildProfileModel> updateAvatar({
    required String childId,
    required UpdateChildAvatarRequest request,
  });
  Future<List<HomeworkModel>> getHomework({required String childId});
  Future<HomeworkModel> getHomeworkDetail({required String homeworkId});
  Future<List<QuizModel>> getQuizList();
  Future<QuizModel> getQuizDetail({required String quizId});
  Future<QuizResultModel> submitQuiz(SubmitQuizRequest request);
  Future<AchievementModel> getAchievements({required String childId});
}

class ChildRemoteDataSourceImpl implements ChildRemoteDataSource {
  const ChildRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _childBase = '/child';
  static const String _quizBase = '/quiz';

  @override
  Future<ChildProfileModel> getProfile({required String childId}) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('$_childBase/$childId/profile');
      return ChildProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: ChildErrorCodes.profileNotFound);
    }
  }

  @override
  Future<ChildProfileModel> updateProfile({
    required String childId,
    required UpdateChildProfileRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.put<dynamic>(
        '$_childBase/$childId/profile',
        data: request.toJson(),
      );
      return ChildProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        validationCode: ChildErrorCodes.invalidProfileData,
        fallbackCode: ChildErrorCodes.profileUpdateFailed,
      );
    }
  }

  @override
  Future<ChildProfileModel> updateAvatar({
    required String childId,
    required UpdateChildAvatarRequest request,
  }) async {
    try {
      final Response<dynamic> res = await _dio.put<dynamic>(
        '$_childBase/$childId/avatar',
        data: request.toJson(),
      );
      return ChildProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, fallbackCode: ChildErrorCodes.profileUpdateFailed);
    }
  }

  @override
  Future<List<HomeworkModel>> getHomework({required String childId}) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('$_childBase/$childId/homework');
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              HomeworkModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<HomeworkModel> getHomeworkDetail({required String homeworkId}) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('/homework/$homeworkId');
      return HomeworkModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: ChildErrorCodes.homeworkNotFound);
    }
  }

  @override
  Future<List<QuizModel>> getQuizList() async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>(_quizBase);
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              QuizModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<QuizModel> getQuizDetail({required String quizId}) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('$_quizBase/$quizId');
      return QuizModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: ChildErrorCodes.quizNotFound);
    }
  }

  @override
  Future<QuizResultModel> submitQuiz(SubmitQuizRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '$_quizBase/${request.quizId}/submit',
        data: request.toJson(),
      );
      return QuizResultModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        fallbackCode: ChildErrorCodes.quizSubmissionFailed,
      );
    }
  }

  @override
  Future<AchievementModel> getAchievements({required String childId}) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('$_childBase/$childId/achievements');
      return AchievementModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: ChildErrorCodes.achievementUnavailable,
      );
    }
  }

  AppException _mapError(
    DioException e, {
    String? notFoundCode,
    String? validationCode,
    String? fallbackCode,
  }) {
    final bool isTransport = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;

    if (isTransport) {
      return const NetworkException('Unable to reach the server. Check your connection.');
    }

    final int? status = e.response?.statusCode;
    if (status == 404 && notFoundCode != null) {
      return ServerException('Resource not found', notFoundCode, e);
    }
    if (status == 422 && validationCode != null) {
      return ValidationException('Validation failed', validationCode, e);
    }
    if (status == 401 || status == 403) {
      return UnauthorizedException('Unauthorized', null, e);
    }
    return ServerException('Something went wrong', fallbackCode, e);
  }
}
