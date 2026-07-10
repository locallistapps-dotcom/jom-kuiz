import '../../core/constants/app_constants.dart';
import '../../core/storage/token_storage.dart';

/// Owns read/write/clear of JWT access + refresh tokens in secure storage.
///
/// This is intentionally the *only* place in the app allowed to touch
/// [StorageKeys.accessToken] / [StorageKeys.refreshToken] directly.
/// [AuthInterceptor] and [SessionManager] should depend on this class rather
/// than reading storage themselves.
class TokenManager {
  TokenManager(this._storage);

  final TokenStorage _storage;

  /// Holds the refresh token in memory only when the caller opted out of
  /// persistence (`rememberMe: false`), so the session ends when the app
  /// process ends rather than surviving a restart.
  String? _inMemoryRefreshToken;

  Future<String?> readAccessToken() => _storage.read(StorageKeys.accessToken);

  Future<String?> readRefreshToken() async {
    if (_inMemoryRefreshToken != null) return _inMemoryRefreshToken;
    return _storage.read(StorageKeys.refreshToken);
  }

  /// Persists the access token and its expiry always. The refresh token is
  /// persisted to secure storage only when [persistRefreshToken] is `true`
  /// (i.e. "remember me" is checked); otherwise it is kept in memory only.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    bool persistRefreshToken = true,
  }) async {
    await _storage.write(StorageKeys.accessToken, accessToken);
    await _storage.write(StorageKeys.tokenExpiresAt, expiresAt.toIso8601String());

    if (persistRefreshToken) {
      _inMemoryRefreshToken = null;
      await _storage.write(StorageKeys.refreshToken, refreshToken);
    } else {
      await _storage.delete(StorageKeys.refreshToken);
      _inMemoryRefreshToken = refreshToken;
    }
  }

  /// Whether an access + refresh token pair is currently available (either
  /// persisted or in-memory).
  ///
  /// Does not indicate the access token is still valid -- see
  /// [isAccessTokenExpired] for that.
  Future<bool> get hasValidSession async {
    final String? accessToken = await readAccessToken();
    final String? refreshToken = await readRefreshToken();
    return accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Whether the stored access token has passed its expiry timestamp.
  ///
  /// Returns `true` (treat as expired) when no expiry has been recorded, so
  /// callers default to the safer "attempt refresh" path.
  Future<bool> isAccessTokenExpired() async {
    final String? raw = await _storage.read(StorageKeys.tokenExpiresAt);
    if (raw == null) return true;

    final DateTime? expiresAt = DateTime.tryParse(raw);
    if (expiresAt == null) return true;

    return DateTime.now().isAfter(expiresAt);
  }

  Future<void> clear() async {
    _inMemoryRefreshToken = null;
    await _storage.delete(StorageKeys.accessToken);
    await _storage.delete(StorageKeys.refreshToken);
    await _storage.delete(StorageKeys.tokenExpiresAt);
  }
}
