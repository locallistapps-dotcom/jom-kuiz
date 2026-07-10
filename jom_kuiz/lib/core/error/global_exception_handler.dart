import 'app_exception.dart';
import 'failure.dart';

/// Converts data-layer [AppException]s into presentation-facing [Failure]s.
///
/// This keeps controllers/widgets ignorant of Dio, database drivers, or any
/// other data-layer exception type -- they only ever see [Failure].
abstract final class GlobalExceptionHandler {
  static Failure toFailure(Object error) {
    if (error is UnauthorizedException || error is TokenExpiredException) {
      return UnauthorizedFailure((error as AppException).message);
    }
    if (error is NetworkException) {
      return NetworkFailure(error.message);
    }
    if (error is ServerException) {
      return ServerFailure(error.message);
    }
    if (error is ValidationException) {
      return ValidationFailure(error.message);
    }
    return const UnknownFailure();
  }
}
