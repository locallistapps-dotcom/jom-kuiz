/// Error codes for the Subject module.
///
/// Format: SUBJECT-NNN
abstract final class SubjectErrorCodes {
  /// No subject found for the given ID.
  static const String subjectNotFound = 'SUBJECT-001';

  /// A subject with the same name already exists.
  static const String duplicateSubjectName = 'SUBJECT-002';

  /// The submitted subject data failed validation.
  static const String invalidSubjectData = 'SUBJECT-003';

  /// The subject could not be deleted (e.g. it has dependent chapters).
  static const String subjectDeleteFailed = 'SUBJECT-004';

  /// Generic server-side failure for any subject operation.
  static const String subjectOperationFailed = 'SUBJECT-005';
}
