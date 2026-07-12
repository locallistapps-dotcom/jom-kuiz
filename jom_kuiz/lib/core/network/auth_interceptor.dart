import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/token_manager.dart';
import 'auth_event_bus.dart';

/// Dio interceptor that makes the app session production-ready:
///
/// 1. **Attaches access token** — adds `Authorization: Bearer <token>` to
///    every outgoing request from secure storage.
///
/// 2. **Retries on 401** — when a PostgREST call returns 401 (expired JWT),
///    silently calls GoTrue `/token?grant_type=refresh_token`, saves the new
///    token pair, and retries the original request exactly once.
///
/// 3. **Forces logout on refresh failure** — if the refresh token is missing
///    or the GoTrue call fails, clears local storage and emits
///    [AuthEvent.sessionExpired] so [SessionController] routes to Login.
///
/// 4. **Serialises concurrent refreshes** — only ONE refresh round-trip runs
///    at a time; parallel 401 errors wait on the same [Completer] instead of
///    firing independent GoTrue calls.
///
/// **Loop prevention**: GoTrue endpoint paths (`/token`, `/logout`, etc.) and
/// requests already marked `_retried: true` skip the retry branch entirely.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenManager);

  final TokenManager _tokenManager;

  /// Back-reference to the [Dio] this interceptor is attached to.
  ///
  /// Set by [setParentDio] *after* the [Dio] instance is created — this
  /// breaks the circular dependency (Dio needs the interceptor; interceptor
  /// needs Dio for retry). If `null`, 401 errors are passed through without
  /// retry (should never happen in production).
  Dio? _parentDio;

  /// Concurrent-refresh guard.
  ///
  /// Non-`null` while a refresh is in flight. Subsequent 401 errors await
  /// the same [Completer] instead of firing duplicate GoTrue calls. Resolves
  /// to the new access token on success, or `null` on failure.
  Completer<String?>? _refreshCompleter;

  /// Minimal Dio instance used **only** for the refresh HTTP call.
  ///
  /// Intentionally has **no interceptors** — if the refresh call itself
  /// receives a 401, we must not attempt another refresh (infinite loop).
  /// Uses only the Supabase anon key, which GoTrue accepts for `/token`.
  Dio? _refreshDio;
  Dio get _refresh => _refreshDio ??= Dio(
        BaseOptions(
          baseUrl: '${AppConfig.supabaseUrl}/auth/v1',
          connectTimeout: AppConstants.networkTimeout,
          receiveTimeout: AppConstants.networkTimeout,
          sendTimeout: AppConstants.networkTimeout,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'apikey': AppConfig.supabaseAnonKey,
          },
        ),
      );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Called by DI after [Dio] is constructed to enable 401-retry.
  ///
  /// Without this call the interceptor still attaches tokens to requests, but
  /// cannot retry them (it has no Dio reference to `fetch` through).
  void setParentDio(Dio dio) => _parentDio = dio;

  // ── Interceptor overrides ─────────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Use `.then()` so `handler.next()` is guaranteed to be called from a
    // chained Future (not from an `async void` body). On Flutter Web, an
    // `async void` microtask can be delayed past the HTTP dispatch, causing
    // the Authorization header to be missing — Supabase then treats the
    // request as anonymous and RLS blocks it.
    _tokenManager.readAccessToken().then((String? token) {
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }).catchError((Object _) {
      // Token read failed — continue without auth header rather than
      // leaving the Dio chain hanging indefinitely.
      handler.next(options);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Never retry calls to GoTrue auth endpoints — that causes infinite loops
    // (refresh 401 → retry → refresh 401 → …).
    if (_isAuthEndpoint(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    // Already retried once with a fresh token — give up to avoid loops.
    if (err.requestOptions.extra['_retried'] == true) {
      handler.next(err);
      return;
    }

    // Retry wiring is not set up (should not happen in production).
    if (_parentDio == null) {
      handler.next(err);
      return;
    }

    // Async: refresh token, then retry or propagate.
    _handleUnauthorized(err, handler);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Returns `true` for GoTrue endpoint paths that must never trigger a retry.
  bool _isAuthEndpoint(String path) =>
      path.contains('/token') ||
      path.contains('/logout') ||
      path.contains('/signup') ||
      path.contains('/recover') ||
      path.contains('/user');

  /// Orchestrates refresh + retry for a 401 response.
  Future<void> _handleUnauthorized(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final String? newToken = await _refreshOrWait();

      if (newToken == null || newToken.isEmpty) {
        // Refresh failed — session is dead; propagate the original 401.
        handler.next(err);
        return;
      }

      // Retry the original request with the newly refreshed token.
      // `_parentDio.fetch` goes through the interceptor chain again, but the
      // `_retried: true` extra flag prevents re-entry into this branch.
      final RequestOptions opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      opts.extra['_retried'] = true;

      final Response<dynamic> response =
          await _parentDio!.fetch<dynamic>(opts);
      handler.resolve(response);
    } catch (_) {
      // Unexpected error during retry — pass the original 401 through.
      handler.next(err);
    }
  }

  /// Performs one token refresh, or waits for one already in progress.
  ///
  /// Returns the new access token on success, or `null` on failure. On
  /// failure the session is cleared and [AuthEvent.sessionExpired] is emitted.
  ///
  /// Concurrent callers share a single [Completer] so only one HTTP round-trip
  /// is made regardless of how many simultaneous 401 errors triggered refresh.
  Future<String?> _refreshOrWait() async {
    // Another concurrent 401 already kicked off a refresh — wait for it.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final String? refreshToken = await _tokenManager.readRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token stored — cannot renew; end session.
        await _tokenManager.clear();
        AuthEventBus.instance.emit(AuthEvent.sessionExpired);
        _refreshCompleter!.complete(null);
        return null;
      }

      // Call GoTrue directly via the interceptor-free Dio to avoid loops.
      final Response<dynamic> res = await _refresh.post<dynamic>(
        '/token',
        queryParameters: <String, String>{'grant_type': 'refresh_token'},
        data: <String, String>{'refresh_token': refreshToken},
      );

      final Map<String, dynamic> body = res.data as Map<String, dynamic>;
      final String newAccess = body['access_token'] as String;
      final String newRefresh = body['refresh_token'] as String;
      final int expiresIn = body['expires_in'] as int;

      // Persist new token pair — refresh token rotation requires updating
      // the stored refresh token on every successful refresh.
      await _tokenManager.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );

      AuthEventBus.instance.emit(AuthEvent.tokenRefreshed);
      _refreshCompleter!.complete(newAccess);
      return newAccess;
    } catch (_) {
      // GoTrue returned an error (e.g. 400 "Invalid Refresh Token") or a
      // network failure occurred — clear storage and force re-login.
      await _tokenManager.clear();
      AuthEventBus.instance.emit(AuthEvent.sessionExpired);
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      // Always reset the lock so future 401s can start a fresh refresh.
      _refreshCompleter = null;
    }
  }
}
