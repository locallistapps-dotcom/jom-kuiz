import '../../core/error/app_exception.dart';
import '../../core/error/global_exception_handler.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/parent_profile.dart';
import '../../domain/repositories/parent_repository.dart';
import '../datasources/parent_remote_data_source.dart';
import '../models/parent_requests.dart';

/// Concrete [ParentRepository] backed by [ParentRemoteDataSource].
///
/// Ready to sit in front of a PostgreSQL-persisted `parents` table -- this
/// repository only knows about the REST contract, not the database.
class ParentRepositoryImpl implements ParentRepository {
  const ParentRepositoryImpl(this._remoteDataSource);

  final ParentRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ParentProfile>> getProfile() async {
    try {
      final profile = await _remoteDataSource.getProfile();
      return Result<ParentProfile>.success(profile.toEntity());
    } on AppException catch (e) {
      return Result<ParentProfile>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ParentProfile>> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? country,
    String? state,
    String? city,
    String? gender,
    DateTime? dateOfBirth,
    String? language,
    String? bio,
  }) async {
    try {
      final profile = await _remoteDataSource.updateProfile(
        UpdateProfileRequest(
          fullName: fullName,
          phoneNumber: phoneNumber,
          country: country,
          state: state,
          city: city,
          gender: gender,
          dateOfBirth: dateOfBirth,
          language: language,
          bio: bio,
        ),
      );
      return Result<ParentProfile>.success(profile.toEntity());
    } on AppException catch (e) {
      return Result<ParentProfile>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ParentProfile>> updateAvatar({required String localFilePath}) async {
    try {
      final profile = await _remoteDataSource.updateAvatar(
        UpdateAvatarRequest(localFilePath: localFilePath),
      );
      return Result<ParentProfile>.success(profile.toEntity());
    } on AppException catch (e) {
      return Result<ParentProfile>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.updatePassword(
        ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword),
      );
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<ParentProfile>> updateSettings({
    String? language,
    bool? notificationEnabled,
  }) async {
    try {
      final profile = await _remoteDataSource.updateSettings(
        UpdateSettingsRequest(language: language, notificationEnabled: notificationEnabled),
      );
      return Result<ParentProfile>.success(profile.toEntity());
    } on AppException catch (e) {
      return Result<ParentProfile>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Result<void>.success(null);
    } on AppException catch (e) {
      return Result<void>.failure(GlobalExceptionHandler.toFailure(e));
    }
  }
}
