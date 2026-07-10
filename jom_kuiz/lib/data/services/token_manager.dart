import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';

/// Owns read/write/clear of JWT access + refresh tokens in secure storage.
///
/// This is intentionally the *only* place in the app allowed to touch
/// [StorageKeys.accessToken] / [StorageKeys.refreshToken] directly.
/// [AuthInterceptor] and [SessionManager] should depend on this class rather
/// than reading secure storage themselves.
class TokenManager {
  TokenManager(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<String?> readRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    if (expiresAt != null) {
      await _storage.write(
        key: StorageKeys.tokenExpiresAt,
        value: expiresAt.toIso8601String(),
      );
    }
  }

  Future<bool> get hasValidSession async {
    final String? token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.tokenExpiresAt);
  }
}
