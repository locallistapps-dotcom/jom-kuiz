import 'package:dio/dio.dart';

import '../../data/services/token_manager.dart';

/// Dio interceptor that attaches the current access token to outgoing
/// requests.
///
/// Reactive refresh-on-401 is intentionally NOT implemented here to avoid a
/// circular dependency (this lives in `core/network`, while the refresh flow
/// lives in `AuthService`, which itself depends on a `Dio` built from this
/// interceptor). Proactive refresh is instead handled by
/// `AuthService.checkSession()`, called from the splash screen / session
/// controller on app start and resume.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenManager);

  final TokenManager _tokenManager;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Use .then() instead of async/await so handler.next() is guaranteed to
    // be called from a chained Future — not from an `async void` body whose
    // Future is silently discarded by Dio's interceptor caller.  On Flutter
    // Web the JS event loop can dispatch the HTTP request before an
    // `async void` microtask runs, causing the Authorization header to be
    // missing and Supabase to treat the request as anonymous (no JWT → RLS
    // blocks writes that require is_admin()).
    _tokenManager.readAccessToken().then((String? accessToken) {
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      handler.next(options);
    }).catchError((Object _) {
      // Token read failed — proceed without auth header rather than
      // leaving the chain hanging.
      handler.next(options);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO(auth): on 401, surface a session-expired signal so the UI can
    // route to Login. See `SessionController.refresh()` for the pull-based
    // equivalent used today.
    handler.next(err);
  }
}
