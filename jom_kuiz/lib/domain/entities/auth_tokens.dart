import 'package:equatable/equatable.dart';

/// A JWT access/refresh token pair returned by the Authentication API.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  bool get isAccessTokenExpired => DateTime.now().isAfter(accessTokenExpiresAt);

  @override
  List<Object?> get props => <Object?>[accessToken, refreshToken, accessTokenExpiresAt];
}
