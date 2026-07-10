/// Base type for exceptions thrown by the data layer (services, repositories,
/// API layer). The [GlobalExceptionHandler] maps these into [Failure]s (or
/// user-facing messages) at the boundary of the presentation layer.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection', super.code, super.cause]);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error', super.code, super.cause]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized', super.code, super.cause]);
}

class TokenExpiredException extends AppException {
  const TokenExpiredException([super.message = 'Token expired', super.code, super.cause]);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation failed', super.code, super.cause]);
}
