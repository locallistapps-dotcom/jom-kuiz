---
name: Test provider overrides
description: The minimum set of Riverpod provider overrides required to avoid MissingPluginException in unit and widget tests.
---

`flutter_secure_storage` throws `MissingPluginException` outside a real device/emulator. The provider chain that reaches it is:

```
tokenStorageProvider → SecureTokenStorage(FlutterSecureStorage)
  ↑
tokenManagerProvider
  ↑
sessionManagerProvider
  ↑
parentServiceProvider / authServiceProvider / ...
  ↑
parentControllerProvider / sessionControllerProvider / ...
```

**Rule:** Any test that instantiates a `ProviderContainer` (unit test) or `ProviderScope` (widget test) and reads anything in the chain above `tokenStorageProvider` MUST override `tokenStorageProvider`:

```dart
// Unit test
ProviderContainer(
  overrides: [
    tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
    parentRepositoryProvider.overrideWithValue(fakeRepo),
  ],
)

// Widget test
ProviderScope(
  overrides: [
    tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
    parentRepositoryProvider.overrideWithValue(fakeRepo),
  ],
  child: ...,
)
```

`FakeTokenStorage` lives at `test/helpers/fake_token_storage.dart` — an in-memory `TokenStorage` implementation shared across all tests.

**Why:** Overriding only a mid-chain provider (e.g. `parentRepositoryProvider`) does not prevent `sessionManagerProvider` from constructing with a real `FlutterSecureStorage`. The override must happen at the root of the chain.

**How to apply:** Before writing a new test file that touches any feature controller or service, add the `tokenStorageProvider` override first.
