/// Placeholder for authentication-related network calls (login, register,
/// refresh, logout).
///
/// Deliberately unimplemented per project scope for this prompt -- only the
/// contract is prepared so [TokenManager] / [SessionManager] / the router
/// have a stable type to depend on. Implement calls against the REST API in
/// a future prompt.
abstract class AuthService {
  /// Exchanges credentials for an access/refresh token pair.
  Future<void> login({required String email, required String password});

  /// Registers a new account.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  /// Exchanges a refresh token for a new access token.
  Future<void> refreshAccessToken();

  /// Invalidates the current session, both locally and (when implemented)
  /// server-side.
  Future<void> logout();
}
