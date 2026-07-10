/// Abstraction over raw key/value secure storage.
///
/// [TokenManager] depends on this interface (not a specific package)
/// so it can be tested with an in-memory fake instead of a real secure
/// storage plugin. [SecureTokenStorage] is the production implementation.
abstract class TokenStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
