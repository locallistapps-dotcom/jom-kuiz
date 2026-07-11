import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/admin_content.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

/// Concrete [AdminRepository] backed by [AdminRemoteDataSource].
class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._dataSource);

  final AdminRemoteDataSource _dataSource;

  @override
  Future<Result<List<AdminContent>>> getContent({
    AdminContentType? type,
  }) async {
    try {
      final List<AdminContentModel> models =
          await _dataSource.getContent(type: type);
      return Result<List<AdminContent>>.success(
        models.map((AdminContentModel m) => m.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Result<List<AdminContent>>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<AdminContent>> getContentById({
    required String contentId,
  }) async {
    try {
      final AdminContentModel model =
          await _dataSource.getContentById(contentId: contentId);
      return Result<AdminContent>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<AdminContent>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<AdminContent>> publishContent({
    required String contentId,
  }) async {
    try {
      final AdminContentModel model =
          await _dataSource.publishContent(contentId: contentId);
      return Result<AdminContent>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<AdminContent>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<AdminContent>> unpublishContent({
    required String contentId,
  }) async {
    try {
      final AdminContentModel model =
          await _dataSource.unpublishContent(contentId: contentId);
      return Result<AdminContent>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<AdminContent>.failure(
          GlobalExceptionHandler.toFailure(e));
    }
  }
}
