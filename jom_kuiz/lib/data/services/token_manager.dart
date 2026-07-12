import 'dart:convert';

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

  /// Whether the stored access token has passed (or is within 60 s of) its
  /// expiry timestamp.
  ///
  /// The 60-second buffer ensures [AuthService.checkSession] proactively
  /// refreshes before the token actually expires, preventing 401 errors
  /// caused by clock skew and network latency on the first post-startup call.
  ///
  /// Returns `true` (treat as expired) when no expiry has been recorded, so
  /// callers default to the safer "attempt refresh" path.
  Future<bool> isAccessTokenExpired() async {
    final String? raw = await _storage.read(StorageKeys.tokenExpiresAt);
    if (raw == null) return true;

    final DateTime? expiresAt = DateTime.tryParse(raw);
    if (expiresAt == null) return true;

    // Treat the token as already expired 60 seconds before its actual expiry
    // to account for clock skew and round-trip latency.
    return DateTime.now()
        .isAfter(expiresAt.subtract(const Duration(seconds: 60)));
  }

  /// Decodes the stored JWT access token and returns the `sub` claim (user UUID).
  ///
  /// Returns `null` when no token is present or the payload cannot be decoded.
  /// Does NOT verify the signature — only used to extract the identity of the
  /// already-authenticated user for an admin role check.
  Future<String?> getUserId() async {
    final String? token = await readAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      // Restore base64 padding removed by JWT encoding.
      switch (payload.length % 4) {
        case 2:
          payload += '==';
        case 3:
          payload += '=';
        default:
          break;
      }
      final String decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> claims =
          jsonDecode(decoded) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _inMemoryRefreshToken = null;
    await _storage.delete(StorageKeys.accessToken);
    await _storage.delete(StorageKeys.refreshToken);
    await _storage.delete(StorageKeys.tokenExpiresAt);
  }
}
