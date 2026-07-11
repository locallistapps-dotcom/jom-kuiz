import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/services/session_manager.dart';
import '../../data/services/token_manager.dart';
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
