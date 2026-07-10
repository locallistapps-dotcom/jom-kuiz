# Data models

DTOs mapping raw REST API JSON to Dart objects live here (e.g. `user_model.dart`,
generated with `json_serializable`/`freezed`). No models are defined yet — this
directory is prepared for the auth/parent/child/quiz feature modules that will
be implemented in future prompts.

Convention once models are added:

- `<name>_model.dart` — the DTO (`@JsonSerializable`), with `fromJson`/`toJson`.
- Map DTOs to `domain/entities/<name>.dart` in the repository layer; the
  presentation layer should only ever see domain entities, never raw DTOs.
