/// High-level session state used to drive splash-screen redirects and route
/// guarding.
enum SessionStatus {
  /// A valid access token (or a refreshable refresh token) is present.
  authenticated,

  /// No valid session -- user should see the Login screen.
  unauthenticated,
}
