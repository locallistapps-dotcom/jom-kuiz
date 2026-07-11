import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/datasources/teacher_remote_data_source.dart';
import '../../data/repositories/teacher_repository_impl.dart';
import '../../data/services/teacher_service.dart';
import '../../domain/repositories/teacher_repository.dart';

/// Wires the Teacher feature's dependency chain:
/// `Dio → TeacherRemoteDataSource → TeacherRepository → TeacherService`.
///
/// Infrastructure providers (`dioProvider`) live in `core/di/providers.dart`.

final Provider<TeacherRemoteDataSource> teacherRemoteDataSourceProvider =
    Provider<TeacherRemoteDataSource>(
  (Ref ref) => TeacherRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<TeacherRepository> teacherRepositoryProvider =
    Provider<TeacherRepository>(
  (Ref ref) =>
      TeacherRepositoryImpl(ref.watch(teacherRemoteDataSourceProvider)),
);

final Provider<TeacherService> teacherServiceProvider =
    Provider<TeacherService>(
  (Ref ref) =>
      TeacherService(repository: ref.watch(teacherRepositoryProvider)),
);

/// Holds the ID of the teacher currently logged in / being viewed.
///
/// Set this provider before navigating into any teacher screen. In a future
/// prompt, this will be sourced directly from the session token (JWT sub
/// claim). For now it is seeded by the parent dashboard or auth flow.
final StateProvider<String> currentTeacherIdProvider =
    StateProvider<String>((Ref ref) => '');
