/// Error codes for the Year module.
///
/// Format: YEAR-NNN
abstract final class YearErrorCodes {
  /// No year found for the given ID.
  static const String yearNotFound = 'YEAR-001';

  /// A year with the same name already exists.
  static const String duplicateYearName = 'YEAR-002';

  /// The submitted year data failed validation.
  static const String invalidYearData = 'YEAR-003';

  /// The year could not be deleted (e.g. it has dependent chapters).
  static const String yearDeleteFailed = 'YEAR-004';

  /// Generic server-side failure for any year operation.
  static const String yearOperationFailed = 'YEAR-005';
}
