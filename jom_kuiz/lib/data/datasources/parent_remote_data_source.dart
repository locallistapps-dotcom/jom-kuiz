import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/parent_error_codes.dart';
import '../../core/logger/app_logger.dart';
import '../models/parent_profile_model.dart';
import '../models/parent_requests.dart';

/// API-layer client for the `public.parents` PostgREST table.
///
/// [_postgrestDio] must have:
///   • baseUrl = `{supabaseUrl}/rest/v1`
///   • `apikey: {SUPABASE_ANON_KEY}` header (set on [ApiClient])
///   • `Authorization: Bearer {token}` via [AuthInterceptor]
///
/// [_authDio] must have:
///   • baseUrl = `{supabaseUrl}/auth/v1`
///   • `apikey: {SUPABASE_ANON_KEY}` header
///   Used only for [updatePassword], which calls Supabase's user-update API.
///
/// RLS policies on `public.parents` (user_id = auth.uid()) ensure every
/// query is automatically scoped to the authenticated user — no explicit
/// user-ID filter is needed in application code.
abstract class ParentRemoteDataSource {
  Future<ParentProfileModel> getProfile();
  Future<ParentProfileModel> updateProfile(UpdateProfileRequest request);
  Future<ParentProfileModel> updateAvatar(UpdateAvatarRequest request);
  Future<void> updatePassword(ChangePasswordRequest request);
  Future<ParentProfileModel> updateSettings(UpdateSettingsRequest request);
  Future<void> deleteAccount();
}

class ParentRemoteDataSourceImpl implements ParentRemoteDataSource {
  const ParentRemoteDataSourceImpl(this._postgrestDio, this._authDio);

  /// Dio instance targeting `{supabaseUrl}/rest/v1` (PostgREST).
  final Dio _postgrestDio;

  /// Dio instance targeting `{supabaseUrl}/auth/v1` (GoTrue).
  final Dio _authDio;

  // PostgREST table path — plural snake_case of the `public.parents` table.
  static const String _table = '/parents';

  // ── Fetch ──────────────────────────────────────────────────────────────────

  @override
  Future<ParentProfileModel> getProfile() async {
    try {
      AppLogger.instance.debug('PostgREST GET ${{_table}} (RLS: own row only)');
      final Response<dynamic> response = await _postgrestDio.get<dynamic>(
        _table,
        queryParameters: <String, String>{
          'select': '*',
          'limit': '1',
        },
      );
      final List<dynamic> rows = response.data as List<dynamic>;
      if (rows.isEmpty) {
        // The auth trigger creates a parent row on signup.  If empty, the
        // trigger didn't fire — surface a clear error so it's easy to debug.
        AppLogger.instance.error(
          'parents table returned 0 rows for the authenticated user. '
          'The on_auth_user_created trigger may not be deployed.',
        );
        throw ServerException(
          'Your profile could not be found. Please sign out and sign in again.',
          ParentErrorCodes.profileNotFound,
        );
      }
      return ParentProfileModel.fromJson(rows.first as Map<String, dynamic>);
    } on DioException catch (e) {
      _log('getProfile', e);
      throw _mapError(e, notFoundCode: ParentErrorCodes.profileNotFound);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  @override
  Future<ParentProfileModel> updateProfile(UpdateProfileRequest request) async {
    try {
      final Response<dynamic> response = await _postgrestDio.patch<dynamic>(
        _table,
        data: request.toJson()..removeWhere((_, v) => v == null),
        options: Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> rows = response.data as List<dynamic>;
      return ParentProfileModel.fromJson(rows.first as Map<String, dynamic>);
    } on DioException catch (e) {
      _log('updateProfile', e);
      throw _mapError(
        e,
        validationCode: ParentErrorCodes.invalidPhoneNumber,
        fallbackCode: ParentErrorCodes.profileUpdateFailed,
      );
    }
  }

  @override
  Future<ParentProfileModel> updateAvatar(UpdateAvatarRequest request) async {
    try {
      // `profile_photo` stores the URL/path of the uploaded avatar.
      final Response<dynamic> response = await _postgrestDio.patch<dynamic>(
        _table,
        data: <String, String>{'profile_photo': request.localFilePath},
        options: Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> rows = response.data as List<dynamic>;
      return ParentProfileModel.fromJson(rows.first as Map<String, dynamic>);
    } on DioException catch (e) {
      _log('updateAvatar', e);
      throw _mapError(e, fallbackCode: ParentErrorCodes.avatarUploadFailed);
    }
  }

  @override
  Future<void> updatePassword(ChangePasswordRequest request) async {
    // Password changes are a Supabase Auth operation, not a PostgREST call.
    // PUT /auth/v1/user with the new password; the access token in the
    // Authorization header is the user identity proof.
    try {
      await _authDio.put<dynamic>(
        '/user',
        data: <String, String>{'password': request.newPassword},
      );
    } on DioException catch (e) {
      _log('updatePassword', e);
      throw _mapError(e, fallbackCode: ParentErrorCodes.passwordUpdateFailed);
    }
  }

  @override
  Future<ParentProfileModel> updateSettings(UpdateSettingsRequest request) async {
    try {
      final Response<dynamic> response = await _postgrestDio.patch<dynamic>(
        _table,
        data: request.toJson()..removeWhere((_, v) => v == null),
        options: Options(headers: <String, String>{'Prefer': 'return=representation'}),
      );
      final List<dynamic> rows = response.data as List<dynamic>;
      return ParentProfileModel.fromJson(rows.first as Map<String, dynamic>);
    } on DioException catch (e) {
      _log('updateSettings', e);
      throw _mapError(e, fallbackCode: ParentErrorCodes.profileUpdateFailed);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      // Removes the parent row; the CASCADE from auth.users handles the
      // rest of the child data.  Deleting the auth.users record itself
      // requires a service-role Edge Function — left as a future task.
      await _postgrestDio.delete<dynamic>(_table);
    } on DioException catch (e) {
      _log('deleteAccount', e);
      throw _mapError(e);
    }
  }

  // ── Error helpers ──────────────────────────────────────────────────────────

  void _log(String method, DioException e) {
    AppLogger.instance.error(
      'ParentDS.$method failed — HTTP ${e.response?.statusCode} — ${e.response?.data}',
      error: e,
    );
  }

  AppException _mapError(
    DioException e, {
    String? notFoundCode,
    String? validationCode,
    String? fallbackCode,
  }) {
    final bool isTransport = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
    if (isTransport) {
      return const NetworkException('Unable to reach the server. Check your connection.');
    }
    final int? status = e.response?.statusCode;
    if (status == 404 && notFoundCode != null) {
      return ServerException('Profile not found', notFoundCode, e);
    }
    if (status == 422 && validationCode != null) {
      return ValidationException('Invalid phone number', validationCode, e);
    }
    if (status == 401 || status == 403) {
      // Surface the real Supabase error — never show a generic string.
      final dynamic body = e.response?.data;
      String msg = 'You are not authorized to perform this action';
      if (body is Map && body['message'] is String) msg = body['message'] as String;
      return UnauthorizedException(msg, null, e);
    }
    return ServerException(
      'Something went wrong, please try again',
      fallbackCode,
      e,
    );
  }
}
