/// Official error codes for the Child module.
abstract final class ChildErrorCodes {
  /// The requested child profile does not exist.
  static const String profileNotFound = 'CHILD-001';

  /// The provided profile data failed server-side validation.
  static const String invalidProfileData = 'CHILD-002';

  /// The profile update request was rejected by the server.
  static const String profileUpdateFailed = 'CHILD-003';

  /// The requested homework assignment does not exist.
  static const String homeworkNotFound = 'CHILD-004';

  /// The requested quiz does not exist.
  static const String quizNotFound = 'CHILD-005';

  /// The quiz submission was rejected by the server.
  static const String quizSubmissionFailed = 'CHILD-006';

  /// Achievement data could not be retrieved.
  static const String achievementUnavailable = 'CHILD-007';

  /// The child account is disabled — login rejected.
  static const String disabledAccount = 'CHILD-008';

  /// The student ID, username, or password supplied for child login is wrong.
  static const String invalidCredentials = 'CHILD-009';
}
