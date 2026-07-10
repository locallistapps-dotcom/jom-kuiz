import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

/// Thin factory around [Dio] configured for the Jom Kuiz REST API.
///
/// This is intentionally minimal: base URL, timeouts, and the auth
/// interceptor hook only. Endpoint-specific calls belong in
/// `data/datasources`, not here.
abstract final class ApiClient {
  static Dio create({required AuthInterceptor authInterceptor}) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConstants.networkTimeout,
        receiveTimeout: AppConstants.networkTimeout,
        sendTimeout: AppConstants.networkTimeout,
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(authInterceptor);

    return dio;
  }
}
