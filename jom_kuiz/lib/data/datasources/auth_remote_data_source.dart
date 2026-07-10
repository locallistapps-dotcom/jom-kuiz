import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/auth_error_codes.dart';
import '../models/auth_requests.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

/// API-layer client for the Authentication REST endpoints.
///
/// Every method issues a real HTTP call through the shared [Dio] instance
/// (see `core/network/api_client.dart`) and maps transport/HTTP failures to
/// [AppException] subtypes carrying an [AuthErrorCodes] code. No backend
/// logic lives here -- these calls simply will not succeed until a real
/// Authentication backend implements the endpoints below.
abstract class AuthRemoteDataSource {
  /// `POST /auth/login`
  Future<AuthTokensModel> login(LoginRequest request);

  /// `POST /auth/register`
  Future<UserModel> register(RegisterRequest request);

  /// `POST /auth/logout`
  Future<void> logout(String refreshToken);

  /// `POST /auth/refresh`
  Future<AuthTokensModel> refresh(String refreshToken);

  /// `POST /auth/forgot-password`
  Future<void> forgotPassword(String email);

  /// `POST /auth/reset-password`
  Future<void> resetPassword(ResetPasswordRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _basePath = '/auth';

  @override
  Future<AuthTokensModel> login(LoginRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_basePath/login',
        data: request.toJson(),
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapLoginError(e);
    }
  }

  @override
  Future<UserModel> register(RegisterRequest request) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_basePath/register',
        data: request.toJson(),
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapRegisterError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<dynamic>(
        '$_basePath/logout',
        data: RefreshRequest(refreshToken: refreshToken).toJson(),
      );
    } on DioException catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<AuthTokensModel> refresh(String refreshToken) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '$_basePath/refresh',
        data: RefreshRequest(refreshToken: refreshToken).toJson(),
      );
      return AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapRefreshError(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post<dynamic>(
        '$_basePath/forgot-password',
        data: ForgotPasswordRequest(email: email).toJson(),
      );
    } on DioException catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post<dynamic>('$_basePath/reset-password', data: request.toJson());
    } on DioException catch (e) {
      throw _mapGenericError(e);
    }
  }

  // -- Error mapping -------------------------------------------------------

  bool _isTransportError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  AppException _mapLoginError(DioException e) {
    if (_isTransportError(e)) return _networkException(e);
    if (e.response?.statusCode == 401) {
      return UnauthorizedException(
        'Invalid email or password',
        AuthErrorCodes.invalidCredentials,
        e,
      );
    }
    return _fallbackException(e);
  }

  AppException _mapRegisterError(DioException e) {
    if (_isTransportError(e)) return _networkException(e);
    if (e.response?.statusCode == 409) {
      return ServerException(
        'An account with this email already exists',
        AuthErrorCodes.emailAlreadyExists,
        e,
      );
    }
    return _fallbackException(e);
  }

  AppException _mapRefreshError(DioException e) {
    if (_isTransportError(e)) return _networkException(e);
    if (e.response?.statusCode == 401) {
      return TokenExpiredException(
        'Session expired, please log in again',
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

  AppException _networkException(DioException e) {
    return NetworkException(
      'Unable to reach the server. Check your connection.',
      AuthErrorCodes.networkError,
      e,
    );
  }

  AppException _fallbackException(DioException e) {
    final int? status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return UnauthorizedException(
        'You are not authorized to perform this action',
        AuthErrorCodes.unauthorized,
        e,
      );
    }
    // No official AUTH-0xx code covers a generic/unclassified server error
    // (the five codes are specific to credentials, duplicate email, token
    // expiry, authorization, and connectivity) -- leave `code` null rather
    // than mislabel this as AUTH-005 (network error), which it is not.
    return ServerException(
      'Something went wrong, please try again',
      null,
      e,
    );
  }
}
