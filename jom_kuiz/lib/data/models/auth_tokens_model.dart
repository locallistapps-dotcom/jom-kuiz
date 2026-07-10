import '../../domain/entities/auth_tokens.dart';

/// Wire format for a JWT access/refresh token pair.
///
/// The API is expected to return `expires_in` (seconds until the access
/// token expires) rather than an absolute timestamp, since clocks between
/// client and server can drift -- we compute the absolute expiry locally
/// relative to `DateTime.now()` at the moment the response is received.
class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    final int expiresInSeconds = json['expires_in'] as int;
    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenExpiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
    );
  }

  AuthTokens toEntity() {
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
    );
  }
}
