import '../../core/utils/result.dart';
import '../entities/year.dart';

/// Abstract contract for Year CRUD operations.
///
/// The implementation is backed by Supabase REST (PostgREST) via the shared
/// Dio instance. All methods return [Result] — no exceptions escape this layer.
///
/// Future Subject-Year linking is resolved via ChapterRepository, not here.
abstract interface class YearRepository {
  /// Returns the full year list, optionally filtered and sorted.
  Future<Result<List<Year>>> getYears({
    String? search,
    YearSortOrder sortOrder = YearSortOrder.displayOrderAsc,
    bool? isActive,
  });

  /// Returns a single year by primary key.
  Future<Result<Year>> getYearById({required String yearId});

  /// Creates a new year level.
  Future<Result<Year>> createYear({
    required String yearName,
    int displayOrder,
  });

  /// Updates all mutable fields of an existing year.
  Future<Result<Year>> updateYear({
    required String yearId,
    required String yearName,
    required int displayOrder,
    required bool isActive,
  });

  /// Hard-deletes a year. Returns [Result.success] with `null` on success.
  Future<Result<void>> deleteYear({required String yearId});

  /// Flips [Year.isActive] for the given [yearId].
  Future<Result<Year>> toggleActive({
    required String yearId,
    required bool isActive,
  });
}
