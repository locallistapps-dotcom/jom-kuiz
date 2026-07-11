import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/services/session_manager.dart';
import '../../data/services/token_manager.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../logger/app_logger.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../storage/secure_token_storage.dart';
import '../storage/token_storage.dart';

/// Root dependency-injection providers.
///
/// This file wires up infrastructure shared across features: secure/local
/// storage, token/session management, and the HTTP client. Feature-specific
/// providers (repositories, services built on top of these, controllers)
/// live in `presentation/providers/<feature>_providers.dart`.

final Provider<FlutterSecureStorage> secureStorageProvider = Provider<FlutterSecureStorage>(
  (Ref ref) => const FlutterSecureStorage(
    // Web: explicit db/key names ensure consistent localStorage keys across
    // page refreshes and prevent the crypto.subtle key-lookup from hanging.
    webOptions: WebOptions(
      dbName: 'JomKuizStorage',
      publicKey: 'JomKuizStorageKey',
    ),
  ),
);

final Provider<TokenStorage> tokenStorageProvider = Provider<TokenStorage>(
  (Ref ref) => SecureTokenStorage(ref.watch(secureStorageProvider)),
);

final Provider<TokenManager> tokenManagerProvider = Provider<TokenManager>(
  (Ref ref) => TokenManager(ref.watch(tokenStorageProvider)),
);

final Provider<SessionManager> sessionManagerProvider = Provider<SessionManager>(
  (Ref ref) => SessionManager(ref.watch(tokenManagerProvider)),
);

final Provider<AuthInterceptor> authInterceptorProvider = Provider<AuthInterceptor>(
  (Ref ref) => AuthInterceptor(ref.watch(tokenManagerProvider)),
);

final Provider<Dio> dioProvider = Provider<Dio>(
  (Ref ref) => ApiClient.create(
    authInterceptor: ref.watch(authInterceptorProvider),
  ),
);

/// Dedicated Dio instance for Supabase Auth endpoints (`/auth/v1/…`).
///
/// Distinct from [dioProvider] (which targets `/rest/v1` PostgREST) because:
///  - Auth uses a different base-path (`/auth/v1` vs `/rest/v1`).
///  - Auth requires the `apikey` header on every call (anon key).
///  - Auth endpoints have different request/response shapes to PostgREST.
final Provider<Dio> authDioProvider = Provider<Dio>((Ref ref) {
  final String supabaseUrl = AppConfig.supabaseUrl;
  final String anonKey = AppConfig.supabaseAnonKey;

  // Fail loudly in logs so the build-time dart-define omission is obvious.
  if (supabaseUrl.isEmpty) {
    AppLogger.instance.error(
      'SUPABASE_URL is empty — auth calls will fail. '
      'Pass --dart-define=SUPABASE_URL=https://<ref>.supabase.co at build time.',
    );
  } else {
    AppLogger.instance.debug('Auth Dio base URL: $supabaseUrl/auth/v1');
  }
  if (anonKey.isEmpty) {
    AppLogger.instance.error(
      'SUPABASE_ANON_KEY is empty — auth calls will fail. '
      'Pass --dart-define=SUPABASE_ANON_KEY=<key> at build time.',
    );
  } else {
    AppLogger.instance.debug('SUPABASE_ANON_KEY present (length ${anonKey.length})');
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: '$supabaseUrl/auth/v1',
      connectTimeout: AppConstants.networkTimeout,
      receiveTimeout: AppConstants.networkTimeout,
      sendTimeout: AppConstants.networkTimeout,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey': anonKey,
      },
    ),
  );
  // Attach stored access token on authenticated calls (logout, user-update).
  dio.interceptors.add(ref.watch(authInterceptorProvider));
  return dio;
});
