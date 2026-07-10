import '../error/failure.dart';

/// Minimal `Either`-style result type used at repository boundaries so
/// controllers can pattern-match success/failure without throwing.
///
/// Kept dependency-free (no `dartz`/`fpdart`) to minimize the dependency
/// surface for this foundation prompt.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final Result<T> self = this;
    if (self is Success<T>) return success(self.data);
    if (self is ResultFailure<T>) return failure(self.failure);
    throw StateError('Unreachable');
  }
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}
