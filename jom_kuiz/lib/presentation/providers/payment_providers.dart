import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/providers.dart';
import '../../core/network/auth_interceptor.dart';
import '../../data/datasources/payment_remote_data_source.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/services/payment_service.dart';
import '../../domain/repositories/payment_repository.dart';

/// Dependency chain:
///
/// ```
/// dioProvider (PostgREST)  ──┐
///                             ├─ PaymentRemoteDataSource
/// functionsDioProvider     ──┘         │
///                                      ▼
///                              PaymentRepository
///                                      │
///                                      ▼
///                               PaymentService
/// ```

/// A separate [Dio] instance pointed at Supabase Edge Functions.
///
/// Base URL: `{supabaseUrl}/functions/v1`
/// Auth: same JWT-bearer interceptor as the REST client.
/// Also adds `apikey` header so Supabase can identify the anon client.
final Provider<Dio> functionsDioProvider = Provider<Dio>((Ref ref) {
  final AuthInterceptor authInterceptor = ref.watch(authInterceptorProvider);
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.supabaseUrl}/functions/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
      },
    ),
  );
  dio.interceptors.add(authInterceptor);
  return dio;
});

final Provider<PaymentRemoteDataSource> paymentRemoteDataSourceProvider =
    Provider<PaymentRemoteDataSource>(
  (Ref ref) => PaymentRemoteDataSourceImpl(
    restDio: ref.watch(dioProvider),
    functionsDio: ref.watch(functionsDioProvider),
  ),
);

final Provider<PaymentRepository> paymentRepositoryProvider =
    Provider<PaymentRepository>(
  (Ref ref) =>
      PaymentRepositoryImpl(ref.watch(paymentRemoteDataSourceProvider)),
);

final Provider<PaymentService> paymentServiceProvider =
    Provider<PaymentService>(
  (Ref ref) => PaymentService(repo: ref.watch(paymentRepositoryProvider)),
);
