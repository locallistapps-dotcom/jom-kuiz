import '../../core/utils/result.dart';
import '../entities/parent_profile.dart';

/// Parent profile contract implemented by [ParentRepositoryImpl].
///
/// API-facing only (like [AuthRepository]) -- ready to sit in front of a
/// PostgreSQL-persisted `parents` table without leaking storage concerns
/// into the domain layer.
abstract class ParentRepository {
  /// `GET /parent/profile`
  Future<Result<ParentProfile>> getProfile();

  /// `PUT /parent/profile`
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
  });

  /// `PUT /parent/avatar`
  ///
  /// Accepts a local file path chosen by the picker. No actual upload wiring
  /// yet -- this is the prepared extension point.
  Future<Result<ParentProfile>> updateAvatar({required String localFilePath});

  /// `PUT /parent/password`
  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// `PUT /parent/settings`
  Future<Result<ParentProfile>> updateSettings({
    String? language,
    bool? notificationEnabled,
  });

  /// `DELETE /parent/account`
  Future<Result<void>> deleteAccount();
}
