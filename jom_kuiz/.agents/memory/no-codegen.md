---
name: No-codegen rule
description: All models/DTOs in jom_kuiz must be hand-written; build_runner cannot run in this workspace.
---

All `fromJson`/`toJson`/`copyWith` and Riverpod providers are written manually.

Do NOT use:
- `json_serializable` / `@JsonSerializable`
- `freezed` / `@freezed`
- `riverpod_generator` / `@riverpod`
- Any package that requires `dart run build_runner build`

**Why:** The Replit workspace cannot execute `build_runner` (no persistent process, no file-system watcher), so generated `.g.dart` / `.freezed.dart` files would never be produced and the project would fail to compile.

**How to apply:** Every time a new entity, model, or provider is added, write it fully by hand. Use `sealed class Result<T>` pattern (already in `core/utils/result.dart`) as the reference for hand-written sealed types.
