import 'package:dio/dio.dart';

/// Placeholder Dio interceptor responsible for:
/// - Attaching the current access token to outgoing requests
/// - Triggering a refresh-token flow on 401 responses
///
/// Wiring to [TokenManager] / [AuthService] happens once login is
/// implemented in a future prompt. For now this interceptor is a documented
/// no-op so [ApiClient] has a stable construction point.
class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO(auth): attach `Authorization: Bearer <accessToken>` once
    // TokenManager exposes a synchronous/cached read of the current token.
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO(auth): on 401, attempt a refresh-token exchange via AuthService
    // and retry the original request once. Fall back to logout on failure.
    handler.next(err);
  }
}
