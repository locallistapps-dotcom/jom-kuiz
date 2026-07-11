import 'package:dio/dio.dart';

/// Checks whether a Supabase auth user is in the `admin_users` table.
///
/// A lightweight read: fetches only `user_id` with `limit=1`. If the row
/// exists the user has admin access; any error (including 403) is treated
/// as "not admin" so the app fails safe.
abstract class AdminCheckRemoteDataSource {
  Future<bool> isAdmin({required String userId});
}

class AdminCheckRemoteDataSourceImpl implements AdminCheckRemoteDataSource {
  const AdminCheckRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/admin_users';

  @override
  Future<bool> isAdmin({required String userId}) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'user_id': 'eq.$userId',
          'select': 'user_id',
          'limit': 1,
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      return list.isNotEmpty;
    } catch (_) {
      // Fail safe — any network/auth error → not admin.
      return false;
    }
  }
}
