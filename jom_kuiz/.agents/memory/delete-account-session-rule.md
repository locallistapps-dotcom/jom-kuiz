---
name: deleteAccount session rule
description: Local session must only be cleared AFTER the server confirms account deletion, not on failure.
---

`ParentService.deleteAccount()` clears the local session (via `SessionManager.endSession()`) **only when the server call succeeds**.

```dart
Future<Result<void>> deleteAccount() async {
  final Result<void> result = await _repository.deleteAccount();
  return result.when(
    success: (_) async {
      await _sessionManager.endSession();        // ← only on success
      return const Result<void>.success(null);
    },
    failure: (failure) async => Result<void>.failure(failure),  // ← session untouched
  );
}
```

**Why:** If the server call fails (e.g. network error, 500), the account still exists. Force-logging out the user would leave them unable to retry deletion or see the error message while authenticated. The `RouteGuard` will handle redirect to login automatically once the session is actually gone.

**How to apply:** This same principle applies to any future destructive server action — always confirm success before invalidating local auth state.
