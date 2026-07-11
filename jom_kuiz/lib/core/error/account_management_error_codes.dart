/// Official error codes for the Account Management module (parent CRUD over children).
abstract final class AccountManagementErrorCodes {
  /// Username is already taken by another child.
  static const String duplicateUsername = 'ACCT-001';

  /// The student ID generated or supplied is already in use.
  static const String duplicateStudentId = 'ACCT-002';

  /// Student ID format is invalid (must be 8 numeric digits).
  static const String invalidStudentId = 'ACCT-003';

  /// The account is disabled and cannot perform this action.
  static const String disabledAccount = 'ACCT-004';

  /// Education level value is not one of the recognised options.
  static const String invalidEducationLevel = 'ACCT-005';

  /// Year / grade value does not match the selected education level.
  static const String invalidYearGrade = 'ACCT-006';

  /// The requested child record was not found.
  static const String childNotFound = 'ACCT-007';

  /// The create-child request was rejected by the server.
  static const String createChildFailed = 'ACCT-008';

  /// The update-child request was rejected by the server.
  static const String updateChildFailed = 'ACCT-009';

  /// Password reset failed on the server.
  static const String resetPasswordFailed = 'ACCT-010';

  /// The delete-child request was rejected by the server.
  static const String deleteChildFailed = 'ACCT-011';
}
