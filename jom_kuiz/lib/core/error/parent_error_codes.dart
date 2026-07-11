/// Official error codes for the Parent module.
abstract final class ParentErrorCodes {
  /// The requested parent profile does not exist.
  static const String profileNotFound = 'PARENT-001';

  /// The provided phone number failed format validation.
  static const String invalidPhoneNumber = 'PARENT-002';

  /// The profile update request was rejected by the server.
  static const String profileUpdateFailed = 'PARENT-003';

  /// The avatar upload request was rejected by the server.
  static const String avatarUploadFailed = 'PARENT-004';

  /// The password change request was rejected by the server.
  static const String passwordUpdateFailed = 'PARENT-005';
}
