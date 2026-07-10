import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../network/auth_interceptor.dart';

/// Root dependency-injection providers.
///
/// This file intentionally only wires up infrastructure (HTTP client, secure
/// storage). Feature-specific providers (auth state, repositories, etc.)
/// live in `presentation/providers` once those features are implemented.

final Provider<FlutterSecureStorage> secureStorageProvider = Provider<FlutterSecureStorage>(
  (Ref ref) => const FlutterSecureStorage(),
);

final Provider<AuthInterceptor> authInterceptorProvider = Provider<AuthInterceptor>(
  (Ref ref) => AuthInterceptor(),
);

final Provider<Dio> dioProvider = Provider<Dio>(
  (Ref ref) => ApiClient.create(
    authInterceptor: ref.watch(authInterceptorProvider),
  ),
);
