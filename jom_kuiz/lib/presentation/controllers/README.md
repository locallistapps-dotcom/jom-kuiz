# Controllers

Riverpod `Notifier`/`AsyncNotifier` classes that hold UI state for a screen or
feature and call into `domain/usecases`. Screens read state and dispatch
actions through these controllers -- they should not call repositories or
use cases directly.

No controllers are defined yet -- this directory is prepared for future
feature modules.
