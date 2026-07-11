import '../../core/error/failure.dart';
import '../../core/error/year_error_codes.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/year.dart';
import '../../domain/repositories/year_repository.dart';

/// Orchestrates Year business flows on top of [YearRepository].
///
/// Handles input validation before delegating to the repository so the
/// controller layer never talks to the repository directly.
class YearService {
  const YearService({required YearRepository repository})
      : _repository = repository;

  final YearRepository _repository;

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Result<List<Year>>> getYears({
    String? search,
    YearSortOrder sortOrder = YearSortOrder.displayOrderAsc,
    bool? isActive,
  }) {
    return _repository.getYears(
      search: search?.trim().isEmpty ?? true ? null : search?.trim(),
      sortOrder: sortOrder,
      isActive: isActive,
    );
  }

  Future<Result<Year>> getYearById({required String yearId}) {
    if (yearId.trim().isEmpty) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Year ID must not be empty',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    return _repository.getYearById(yearId: yearId);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<Result<Year>> createYear({
    required String yearName,
    int displayOrder = 0,
  }) {
    final String name = yearName.trim();
    if (name.isEmpty) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Year name is required',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    if (name.length > 100) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Year name must not exceed 100 characters',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    return _repository.createYear(yearName: name, displayOrder: displayOrder);
  }

  Future<Result<Year>> updateYear({
    required String yearId,
    required String yearName,
    required int displayOrder,
    required bool isActive,
  }) {
    final String name = yearName.trim();
    if (yearId.trim().isEmpty) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Year ID must not be empty',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    if (name.isEmpty) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Year name is required',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    if (name.length > 100) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Year name must not exceed 100 characters',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    if (displayOrder < 0) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Display order must be 0 or greater',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    return _repository.updateYear(
      yearId: yearId,
      yearName: name,
      displayOrder: displayOrder,
      isActive: isActive,
    );
  }

  Future<Result<void>> deleteYear({required String yearId}) {
    if (yearId.trim().isEmpty) {
      return Future<Result<void>>.value(
        const Result<void>.failure(
          ValidationFailure(
            'Year ID must not be empty',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    return _repository.deleteYear(yearId: yearId);
  }

  Future<Result<Year>> toggleActive({
    required String yearId,
    required bool isActive,
  }) {
    if (yearId.trim().isEmpty) {
      return Future<Result<Year>>.value(
        const Result<Year>.failure(
          ValidationFailure(
            'Year ID must not be empty',
            YearErrorCodes.invalidYearData,
          ),
        ),
      );
    }
    return _repository.toggleActive(yearId: yearId, isActive: isActive);
  }
}
