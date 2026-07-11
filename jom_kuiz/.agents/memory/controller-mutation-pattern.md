---
name: Controller mutation pattern
description: How AsyncNotifier mutation methods handle success/failure in jom_kuiz — return Result<T>, only update state on success.
---

Mutation methods on `AsyncNotifier` subclasses (e.g. `ParentController`) follow this pattern:

```dart
Future<Result<T>> updateSomething({required String field}) async {
  final Result<T> result = await ref.read(someServiceProvider).updateSomething(field: field);

  result.when(
    success: (T value) {
      state = AsyncValue<T?>.data(value);   // ← update state only on success
    },
    failure: (_) {},                         // ← leave prior state intact
  );
  return result;   // ← caller reads the Result directly for error messages
}
```

**Why:** If the failure branch overwrites `state` with `AsyncValue.error(...)`, the screen's `profileState.valueOrNull` becomes null, which most screens treat as "still loading" — showing a spinner instead of the form. A failed mutation (e.g. invalid phone number) must leave the previously loaded data visible.

**How to apply:**
- Callers (screens) call `result.when(success: ..., failure: ...)` directly on the returned `Result` to show snackbars.
- Never do `ref.read(provider).error` after a mutation — the error won't be in state.
- `when()` callbacks must use block bodies `{ }`, not fat-arrow `=>`, when one callback returns void and the other doesn't — mixed returns cause `R` to widen to `Object?`.
