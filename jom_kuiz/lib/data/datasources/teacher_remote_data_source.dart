import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/teacher_error_codes.dart';
import '../models/teacher_dashboard_model.dart';

/// API-layer client for the Teacher REST endpoints.
///
/// Only the dashboard endpoint is declared here. Attendance, homework,
/// quiz, and announcement endpoints will be added in later prompts.
abstract class TeacherRemoteDataSource {
  Future<TeacherDashboardModel> getDashboard({required String teacherId});
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  const TeacherRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _teacherBase = '/teacher';

  @override
  Future<TeacherDashboardModel> getDashboard(
      {required String teacherId}) async {
    try {
      final Response<dynamic> res =
          await _dio.get<dynamic>('$_teacherBase/$teacherId/dashboard');
      return TeacherDashboardModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

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
    if (status == 404) {
      return ServerException(
          'Teacher not found', notFoundCode ?? TeacherErrorCodes.teacherNotFound, e);
    }
    if (status == 401 || status == 403) {
      return UnauthorizedException(
          'Unauthorized', TeacherErrorCodes.unauthorized, e);
    }
    return ServerException(
        'Dashboard unavailable',
        fallbackCode ?? TeacherErrorCodes.dashboardUnavailable,
        e);
  }
}
