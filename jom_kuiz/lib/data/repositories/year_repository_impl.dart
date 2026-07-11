import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/year.dart';
import '../../domain/repositories/year_repository.dart';
import '../datasources/year_remote_data_source.dart';
import '../models/year_model.dart';

/// Concrete [YearRepository] backed by [YearRemoteDataSource].
///
/// Converts [AppException]s from the datasource into [Failure]s via
/// [GlobalExceptionHandler] so the presentation layer stays exception-free.
class YearRepositoryImpl implements YearRepository {
  const YearRepositoryImpl(this._remoteDataSource);

  final YearRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Year>>> getYears({
    String? search,
    YearSortOrder sortOrder = YearSortOrder.displayOrderAsc,
    bool? isActive,
  }) async {
    try {
      final List<YearModel> models = await _remoteDataSource.getYears(
        search: search,
        sortOrder: sortOrder,
        isActive: isActive,
      );
      return Result<List<Year>>.success(
        models.map((YearModel m) => m.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Result<List<Year>>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Year>> getYearById({required String yearId}) async {
    try {
      final YearModel model =
          await _remoteDataSource.getYearById(yearId: yearId);
      return Result<Year>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Year>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Year>> createYear({
    required String yearName,
    int displayOrder = 0,
  }) async {
    try {
      final YearModel model = await _remoteDataSource.createYear(
        CreateYearRequest(yearName: yearName, displayOrder: displayOrder),
      );
      return Result<Year>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Year>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Year>> updateYear({
    required String yearId,
    required String yearName,
    required int displayOrder,
    required bool isActive,
  }) async {
    try {
      final YearModel model = await _remoteDataSource.updateYear(
        yearId: yearId,
        request: UpdateYearRequest(
          yearName: yearName,
          displayOrder: displayOrder,
          isActive: isActive,
        ),
      );
      return Result<Year>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Year>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteYear({required String yearId}) async {
    try {
      await _remoteDataSource.deleteYear(yearId: yearId);
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<Year>> toggleActive({
    required String yearId,
    required bool isActive,
  }) async {
    try {
      final YearModel model = await _remoteDataSource.toggleActive(
        yearId: yearId,
        request: ToggleYearActiveRequest(isActive: isActive),
      );
      return Result<Year>.success(model.toEntity());
    } on AppException catch (e) {
      return Result<Year>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
