/// Error codes for the Admin CMS module.
///
/// Format: ADMIN-NNN — admin-specific errors surfaced through [Failure] types.
abstract final class AdminErrorCodes {
  /// The current user is not authorised to perform this admin operation.
  static const String unauthorized = 'ADMIN-001';

  /// A required input field is missing or malformed.
  static const String invalidInput = 'ADMIN-002';

  /// The requested admin resource was not found.
  static const String notFound = 'ADMIN-003';

  /// A generic admin operation (create / update) failed.
  static const String operationFailed = 'ADMIN-004';

  /// CSV data could not be parsed (malformed structure / encoding).
  static const String csvParseError = 'ADMIN-005';

  /// One or more CSV rows failed validation during import.
  static const String csvImportFailed = 'ADMIN-006';

  /// A bulk operation (delete / activate) partially or fully failed.
  static const String bulkOperationFailed = 'ADMIN-007';

  /// Duplicate-question operation failed.
  static const String duplicateFailed = 'ADMIN-008';

  /// Export to CSV failed.
  static const String exportFailed = 'ADMIN-009';

  /// Media (image / video) URL is invalid or upload failed.
  static const String mediaUploadFailed = 'ADMIN-010';
}
