import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/auth_error_codes.dart';
import '../../core/logger/app_logger.dart';
import '../models/auth_requests.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

/// API-layer client for Supabase GoTrue Auth endpoints (`/auth/v1/…`).
///
/// The [Dio] instance injected here must have base URL `{supabaseUrl}/auth/v1`
/// and include `apikey: {SUPABASE_ANON_KEY}` in its default headers.
/// Use [authDioProvider] from `core/di/providers.dart`, NOT [dioProvider].
abstract class AuthRemoteDataSource {
  /// `POST /signup`
  Future<UserModel> register(RegisterRequest request);

  /// `POST /token?grant_type=password`
  Future<AuthTokensModel> login(LoginRequest request);

  /// `POST /logout`
  Future<void> logout(String refreshToken);

  /// `POST /token?grant_type=refresh_token`
  Future<AuthTokensModel> refresh(String refreshToken);

  /// `POST /recover`
  Future<void> forgotPassword(String email);

  /// `PUT /user`  (Bearer = recovery access token from magic link)
  Future<void> resetPassword(ResetPasswordRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  // ── Register ───────────────────────────────────────────────────────────────

  @override
  Future<UserModel> register(RegisterRequest request) async {
    try {
      AppLogger.instance.debug('Supabase signup → POST /signup for ${request.email}');
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/signup',
        data: request.toJson(),
      );
      AppLogger.instance.debug('Supabase signup response ${response.statusCode}');
      final Map<String, dynamic> body = response.data as Map<String, dynamic>;
      // When email confirmation is disabled, GoTrue returns a session object
      // with the user nested under a "user" key.
      // When email confirmation is enabled, the body IS the user object.
      final Map<String, dynamic> userJson = body.containsKey('user')
          ? body['user'] as Map<String, dynamic>
          : body;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      _logSupabaseError('register', e);
      throw _mapRegisterError(e);
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  @override
  Future<AuthTokensModel> login(LoginRequest request) async {
    try {
      AppLogger.instance.debug('Supabase login → POST /token?grant_type=password');
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/token',
        queryParameters: <String, String>{'grant_type': 'password'},
        data: request.toJson(),
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logSupabaseError('login', e);
      throw _mapLoginError(e);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  @override
  Future<void> logout(String refreshToken) async {
    try {
      // scope=global invalidates all sessions for this user.
      await _dio.post<dynamic>(
        '/logout',
        queryParameters: <String, String>{'scope': 'global'},
      );
    } on DioException catch (e) {
      _logSupabaseError('logout', e);
      throw _mapGenericError(e);
    }
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  @override
  Future<AuthTokensModel> refresh(String refreshToken) async {
    try {
      AppLogger.instance.debug('Supabase refresh → POST /token?grant_type=refresh_token');
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/token',
        queryParameters: <String, String>{'grant_type': 'refresh_token'},
        data: <String, String>{'refresh_token': refreshToken},
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logSupabaseError('refresh', e);
      throw _mapRefreshError(e);
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────

  @override
  Future<void> forgotPassword(String email) async {
    try {
      AppLogger.instance.debug('Supabase recover → POST /recover');
      await _dio.post<dynamic>(
        '/recover',
        data: <String, String>{'email': email},
      );
    } on DioException catch (e) {
      _logSupabaseError('forgotPassword', e);
      throw _mapGenericError(e);
    }
  }

  // ── Reset password ─────────────────────────────────────────────────────────

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      // The recovery access token from the magic link must be used as Bearer.
      await _dio.put<dynamic>(
        '/user',
        data: <String, String>{'password': request.newPassword},
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer ${request.resetToken}',
          },
        ),
      );
    } on DioException catch (e) {
      _logSupabaseError('resetPassword', e);
      throw _mapGenericError(e);
    }
  }

  // ── Error extraction ───────────────────────────────────────────────────────

  /// Logs the raw Supabase response body so the exact error is visible in
  /// browser DevTools → Console even before the UI surfaces it.
  void _logSupabaseError(String method, DioException e) {
    final int? status = e.response?.statusCode;
    final dynamic body = e.response?.data;
    AppLogger.instance.error(
      'Supabase $method failed — HTTP $status — body: $body',
      error: e,
    );
  }

  /// Extracts the human-readable message from a Supabase/GoTrue error body.
  ///
  /// GoTrue format:  `{"code": 422, "error_code": "weak_password", "msg": "..."}`
  /// OAuth format:   `{"error": "invalid_grant", "error_description": "..."}`
  /// Generic format: `{"message": "..."}`
  String _supabaseMessage(DioException e, String fallback) {
    final dynamic body = e.response?.data;
    if (body is Map<String, dynamic>) {
      for (final String key in <String>['msg', 'error_description', 'message', 'error']) {
        if (body[key] is String && (body[key] as String).isNotEmpty) {
          return body[key] as String;
        }
      }
    }
    return fallback;
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  bool _isTransportError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError;

  AppException _mapLoginError(DioException e) {
    if (_isTransportError(e)) return _networkException(e);
    if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
      return UnauthorizedException(
        _supabaseMessage(e, 'Invalid email or password'),
        AuthErrorCodes.invalidCredentials,
        e,
      );
    }
    return _fallbackException(e);
  }

  AppException _mapRegisterError(DioException e) {
    if (_isTransportError(e)) return _networkException(e);
    if (e.response?.statusCode == 422 || e.response?.statusCode == 409) {
      return ServerException(
        _supabaseMessage(e, 'An account with this email already exists'),
        AuthErrorCodes.emailAlreadyExists,
        e,
      );
    }
    return _fallbackException(e);
  }

  AppException _mapRefreshError(DioException e) {
    if (_isTransportError(e)) return _networkException(e);
    if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
      return TokenExpiredException(
        _supabaseMessage(e, 'Session expired, please log in again'),
        AuthErrorCodes.tokenExpired,
        e,
      );
    }
    return _fallbackException(e);
  }

  AppException _mapGenericError(DioException e) {
    if (_isTransportError(e)) return _networkException(e);
    return _fallbackException(e);
  }

  AppException _networkException(DioException e) => NetworkException(
        'Unable to reach Supabase. Check your connection.',
        AuthErrorCodes.networkError,
        e,
      );

  AppException _fallbackException(DioException e) {
    // Always use the real Supabase error message — never a generic placeholder.
    final String message = _supabaseMessage(
      e,
      'Auth request failed (HTTP ${e.response?.statusCode})',
    );
    return ServerException(message, null, e);
  }
}
