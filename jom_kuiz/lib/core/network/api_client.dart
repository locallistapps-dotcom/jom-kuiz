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
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Supabase requires the anon key on every PostgREST request.
          // Without it Supabase returns 401 "No API key found in request"
          // before even evaluating RLS policies.
          'apikey': AppConfig.supabaseAnonKey,
        },
      ),
    );

    dio.interceptors.add(authInterceptor);

    return dio;
  }
}
