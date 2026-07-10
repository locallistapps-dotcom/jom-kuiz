# Use cases

Single-responsibility application operations (e.g. `LoginUseCase`,
`SubmitQuizAnswerUseCase`) that orchestrate one or more repositories. Callable
classes (`class LoginUseCase { Future<Result<User>> call(...) }`) keep
controllers thin and testable.

No use cases are defined yet -- this directory is prepared for future feature
modules.
