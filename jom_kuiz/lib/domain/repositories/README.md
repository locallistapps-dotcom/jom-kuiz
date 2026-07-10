# Repository interfaces (domain layer)

Abstract contracts implemented by `data/repositories/`. Use cases and
controllers depend on these interfaces, never on concrete implementations --
this is what makes the domain layer independent of the data layer's
networking/storage choices.

No interfaces are defined yet -- this directory is prepared for future
feature modules.
