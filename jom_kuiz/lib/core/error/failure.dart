import 'package:equatable/equatable.dart';

/// Base type for domain/data-layer failures.
///
/// Repositories return `Either`-like results (or throw these as exceptions
/// at the boundary) so the presentation layer never has to catch raw
/// `DioException` / `PostgreSQLException` types directly.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => <Object?>[message, code];

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection', super.code]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error, please try again later', super.code]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired, please log in again', super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input', super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data unavailable', super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong', super.code]);
}
