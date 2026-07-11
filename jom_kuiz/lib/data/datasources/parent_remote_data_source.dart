import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/parent_error_codes.dart';
import '../models/parent_profile_model.dart';
import '../models/parent_requests.dart';

/// API-layer client for the Parent REST endpoints.
///
/// Every method issues a real HTTP call through the shared [Dio] instance.
/// No backend logic lives here -- these calls will not succeed until a real
/// Parent backend implements the endpoints below.
abstract class ParentRemoteDataSource {
  /// `GET /parent/profile`
  Future<ParentProfileModel> getProfile();

  /// `PUT /parent/profile`
  Future<ParentProfileModel> updateProfile(UpdateProfileRequest request);

  /// `PUT /parent/avatar`
  Future<ParentProfileModel> updateAvatar(UpdateAvatarRequest request);

  /// `PUT /parent/password`
  Future<void> updatePassword(ChangePasswordRequest request);

  /// `PUT /parent/settings`
  Future<ParentProfileModel> updateSettings(UpdateSettingsRequest request);

  /// `DELETE /parent/account`
  Future<void> deleteAccount();
}

class ParentRemoteDataSourceImpl implements ParentRemoteDataSource {
  const ParentRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _basePath = '/parent';

  @override
  Future<ParentProfileModel> getProfile() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('$_basePath/profile');
      return ParentProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: ParentErrorCodes.profileNotFound);
    }
  }

  @override
  Future<ParentProfileModel> updateProfile(UpdateProfileRequest request) async {
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        '$_basePath/profile',
        data: request.toJson(),
      );
      return ParentProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
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
      final Response<dynamic> response = await _dio.put<dynamic>(
        '$_basePath/avatar',
        data: request.toJson(),
      );
      return ParentProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, fallbackCode: ParentErrorCodes.avatarUploadFailed);
    }
  }

  @override
  Future<void> updatePassword(ChangePasswordRequest request) async {
    try {
      await _dio.put<dynamic>('$_basePath/password', data: request.toJson());
    } on DioException catch (e) {
      throw _mapError(e, fallbackCode: ParentErrorCodes.passwordUpdateFailed);
    }
  }

  @override
  Future<ParentProfileModel> updateSettings(UpdateSettingsRequest request) async {
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        '$_basePath/settings',
        data: request.toJson(),
      );
      return ParentProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, fallbackCode: ParentErrorCodes.profileUpdateFailed);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<dynamic>('$_basePath/account');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AppException _mapError(
    DioException e, {
    String? notFoundCode,
    String? validationCode,
    String? fallbackCode,
  }) {
    final bool isTransportError = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;

    if (isTransportError) {
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
      return UnauthorizedException(
        'You are not authorized to perform this action',
        null,
        e,
      );
    }
    return ServerException(
      'Something went wrong, please try again',
      fallbackCode,
      e,
    );
  }
}
