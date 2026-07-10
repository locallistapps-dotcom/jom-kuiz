/// Official error codes for the Authentication module.
///
/// Surface these (not raw exception messages) in logs and API-facing error
/// payloads so client and backend teams can correlate issues by code.
abstract final class AuthErrorCodes {
  /// Login rejected -- email/password combination is incorrect.
  static const String invalidCredentials = 'AUTH-001';

  /// Registration rejected -- an account already exists for this email.
  static const String emailAlreadyExists = 'AUTH-002';

  /// Access token has expired and silent refresh also failed.
  static const String tokenExpired = 'AUTH-003';

  /// Request rejected -- caller is not authorized to perform this action.
  static const String unauthorized = 'AUTH-004';

  /// Request could not reach the server (offline, timeout, DNS, etc.).
  static const String networkError = 'AUTH-005';
}
