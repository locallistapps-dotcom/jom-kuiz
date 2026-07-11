import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/teacher_dashboard.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_data_source.dart';

/// Concrete [TeacherRepository] backed by [TeacherRemoteDataSource].
class TeacherRepositoryImpl implements TeacherRepository {
  const TeacherRepositoryImpl(this._remoteDataSource);

  final TeacherRemoteDataSource _remoteDataSource;

  @override
  Future<Result<TeacherDashboard>> getDashboard(
      {required String teacherId}) async {
    try {
      final TeacherDashboardModel model =
          await _remoteDataSource.getDashboard(teacherId: teacherId);
      return Result<TeacherDashboard>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<TeacherDashboard>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
