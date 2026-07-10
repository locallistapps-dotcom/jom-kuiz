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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final String? accessToken = await _tokenManager.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO(auth): on 401, surface a session-expired signal so the UI can
    // route to Login. See `SessionController.refresh()` for the pull-based
    // equivalent used today.
    handler.next(err);
  }
}
