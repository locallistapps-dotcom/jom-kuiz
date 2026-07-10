import 'package:jom_kuiz/core/storage/token_storage.dart';

/// In-memory [TokenStorage] fake shared across tests.
///
/// Widget tests that pump the full app (or anything that reaches
/// [sessionControllerProvider]) must override `tokenStorageProvider` with
/// this, otherwise the real `flutter_secure_storage` plugin is invoked and
/// throws `MissingPluginException` outside a real device/emulator.
class FakeTokenStorage implements TokenStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
