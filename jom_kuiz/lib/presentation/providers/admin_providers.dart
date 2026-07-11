import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/admin_check_remote_data_source.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/services/storage_service.dart';
import '../../domain/repositories/admin_repository.dart';
// tokenManagerProvider lives in core/di/providers.dart (already imported above)

/// Wires the Admin CMS dependency chain:
/// `Dio → AdminRemoteDataSource → AdminRepository`
///
/// Also exposes [storageServiceProvider] and [adminCheckRemoteDataSourceProvider]
/// for use by [AdminContentController], [AdminQuestionFormSheet], and
/// [AuthController] respectively.

final Provider<AdminRemoteDataSource> adminRemoteDataSourceProvider =
    Provider<AdminRemoteDataSource>(
  (Ref ref) => AdminRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<AdminRepository> adminRepositoryProvider =
    Provider<AdminRepository>(
  (Ref ref) =>
      AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider)),
);

/// Checks whether the authenticated user has admin role by querying the
/// `admin_users` table.
final Provider<AdminCheckRemoteDataSource>
    adminCheckRemoteDataSourceProvider =
    Provider<AdminCheckRemoteDataSource>(
  (Ref ref) => AdminCheckRemoteDataSourceImpl(ref.watch(dioProvider)),
);

/// Whether the currently authenticated user has admin privileges.
///
/// Implemented as a [FutureProvider] so it runs automatically on BOTH fresh
/// login and session restore (page refresh).  The dashboard watches it and
/// shows the Admin CMS card only when it resolves to `true`.
///
/// On logout, call `ref.invalidate(isAdminProvider)` so the cached result is
/// discarded and the check re-runs (returning `false`) for the next session.
final FutureProvider<bool> isAdminProvider = FutureProvider<bool>(
  (Ref ref) async {
    final String? userId =
        await ref.read(tokenManagerProvider).getUserId();
    if (userId == null || userId.isEmpty) return false;
    return ref
        .read(adminCheckRemoteDataSourceProvider)
        .isAdmin(userId: userId);
  },
);

/// Uploads files to Supabase Storage. Used by the admin question and
/// content form sheets to upload images / videos picked from the device.
final Provider<StorageService> storageServiceProvider =
    Provider<StorageService>(
  (Ref ref) => StorageService(
    dio: ref.watch(dioProvider),
    tokenManager: ref.watch(tokenManagerProvider),
  ),
);
