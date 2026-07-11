import '../../core/utils/result.dart';
import '../entities/year.dart';

/// Abstract contract for academic year / grade-level operations.
abstract interface class YearRepository {
  /// Returns all year levels, ordered by [Year.level] ascending.
  Future<Result<List<Year>>> getYears();

  /// Returns a single year by [yearId].
  Future<Result<Year>> getYearById({required String yearId});
}
