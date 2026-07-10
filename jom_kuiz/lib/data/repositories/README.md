# Repositories (data layer)

Concrete implementations of the interfaces declared in
`lib/domain/repositories/`. Each implementation composes one or more
`data/datasources` (remote API, local cache) and returns domain entities
wrapped in `core/utils/result.dart`'s `Result<T>`, converting thrown
`AppException`s via `GlobalExceptionHandler.toFailure`.

No repositories are implemented yet — this directory is prepared for future
feature modules (auth, parent, child, quiz).
