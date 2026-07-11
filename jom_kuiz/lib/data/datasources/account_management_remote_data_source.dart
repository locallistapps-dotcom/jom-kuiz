import 'package:dio/dio.dart';

import '../../core/error/account_management_error_codes.dart';
import '../../core/error/app_exception.dart';
import '../models/account_management_models.dart';
import '../models/account_management_requests.dart';

/// API-layer client for parent CRUD over child accounts.
///
/// Uses Supabase PostgREST conventions:
/// - Direct table access (`/children`) for reads / status patches.
/// - RPC functions (`/rpc/create_child`, `/rpc/update_child`,
///   `/rpc/reset_child_password`) for mutations that need server-side
///   password hashing and student-ID generation.
abstract class AccountManagementRemoteDataSource {
  Future<List<ChildManagementModel>> getChildren();
  Future<ChildManagementModel> getChild(String childId);
  Future<ChildManagementModel> createChild(CreateChildRequest request);
  Future<ChildManagementModel> updateChild(
      String childId, UpdateChildRequest request);
  Future<ChildManagementModel> setChildStatus(
      String childId, SetChildStatusRequest request);
  Future<void> resetChildPassword(ResetChildPasswordRequest request);
  Future<bool> isUsernameAvailable(String username);

  /// Authenticates a child via Student ID + username + password.
  ///
  /// Returns a map with keys: `access_token`, `refresh_token`, `expires_in`
  /// (seconds), and `child_id`.
  Future<Map<String, dynamic>> loginChild({
    required String studentId,
    required String username,
    required String password,
  });
}

class AccountManagementRemoteDataSourceImpl
    implements AccountManagementRemoteDataSource {
  const AccountManagementRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _table = '/children';
  static const String _rpcCreate = '/rpc/create_child';
  static const String _rpcUpdate = '/rpc/update_child';
  static const String _rpcResetPassword = '/rpc/reset_child_password';

  // ── Reads ────────────────────────────────────────────────────────────────

  @override
  Future<List<ChildManagementModel>> getChildren() async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _table,
        queryParameters: <String, String>{'order': 'created_at.asc'},
      );
      final List<dynamic> rows = res.data as List<dynamic>;
      return rows
          .map((dynamic e) =>
              ChildManagementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ChildManagementModel> getChild(String childId) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _table,
        queryParameters: <String, String>{
          'id': 'eq.$childId',
          'limit': '1',
        },
      );
      final List<dynamic> rows = res.data as List<dynamic>;
      if (rows.isEmpty) {
        throw ServerException(
          'Child not found',
          AccountManagementErrorCodes.childNotFound,
          null,
        );
      }
      return ChildManagementModel.fromJson(rows.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: AccountManagementErrorCodes.childNotFound,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> loginChild({
    required String studentId,
    required String username,
    required String password,
  }) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '/auth/child/login',
        data: <String, String>{
          'student_id': studentId,
          'username': username,
          'password': password,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(
        e,
        validationCode: AccountManagementErrorCodes.disabledAccount,
        fallbackCode: AccountManagementErrorCodes.createChildFailed,
      );
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _table,
        queryParameters: <String, String>{
          'select': 'id',
          'username': 'eq.$username',
          'limit': '1',
        },
      );
      final List<dynamic> rows = res.data as List<dynamic>;
      return rows.isEmpty;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  @override
  Future<ChildManagementModel> createChild(CreateChildRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _rpcCreate,
        data: request.toJson(),
      );
      return ChildManagementModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        conflictCode: AccountManagementErrorCodes.duplicateUsername,
        validationCode: AccountManagementErrorCodes.invalidEducationLevel,
        fallbackCode: AccountManagementErrorCodes.createChildFailed,
      );
    }
  }

  @override
  Future<ChildManagementModel> updateChild(
      String childId, UpdateChildRequest request) async {
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _rpcUpdate,
        data: <String, dynamic>{
          'child_id': childId,
          ...request.toJson(),
        },
      );
      return ChildManagementModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: AccountManagementErrorCodes.childNotFound,
        conflictCode: AccountManagementErrorCodes.duplicateUsername,
        fallbackCode: AccountManagementErrorCodes.updateChildFailed,
      );
    }
  }

  @override
  Future<ChildManagementModel> setChildStatus(
      String childId, SetChildStatusRequest request) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _table,
        data: request.toJson(),
        queryParameters: <String, String>{'id': 'eq.$childId'},
        options: Options(headers: <String, String>{
          'Prefer': 'return=representation',
        }),
      );
      final List<dynamic> rows = res.data as List<dynamic>;
      return ChildManagementModel.fromJson(rows.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(
        e,
        notFoundCode: AccountManagementErrorCodes.childNotFound,
        fallbackCode: AccountManagementErrorCodes.updateChildFailed,
      );
    }
  }

  @override
  Future<void> resetChildPassword(ResetChildPasswordRequest request) async {
    try {
      await _dio.post<dynamic>(
        _rpcResetPassword,
        data: request.toJson(),
        options: Options(headers: <String, String>{'Prefer': 'return=minimal'}),
      );
    } on DioException catch (e) {
      throw _mapError(
        e,
        fallbackCode: AccountManagementErrorCodes.resetPasswordFailed,
      );
    }
  }

  // ── Error mapping ────────────────────────────────────────────────────────

  AppException _mapError(
    DioException e, {
    String? notFoundCode,
    String? conflictCode,
    String? validationCode,
    String? fallbackCode,
  }) {
    final bool isTransport = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;

    if (isTransport) {
      return const NetworkException(
          'Unable to reach the server. Check your connection.');
    }

    final int? status = e.response?.statusCode;
    if (status == 404 && notFoundCode != null) {
      return ServerException('Child not found', notFoundCode, e);
    }
    if (status == 409 && conflictCode != null) {
      return ServerException('Conflict', conflictCode, e);
    }
    if (status == 422 && validationCode != null) {
      return ValidationException('Validation failed', validationCode, e);
    }
    if (status == 401 || status == 403) {
      return UnauthorizedException('Unauthorized', null, e);
    }
    return ServerException('Something went wrong', fallbackCode, e);
  }
}
