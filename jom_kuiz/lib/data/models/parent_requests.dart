/// Request payloads for the Parent REST endpoints.
///
/// Kept as plain classes (not `Freezed`) so this compiles without codegen.

class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.fullName,
    this.phoneNumber,
    this.country,
    this.state,
    this.city,
    this.gender,
    this.dateOfBirth,
    this.language,
    this.bio,
  });

  final String fullName;
  final String? phoneNumber;
  final String? country;
  final String? state;
  final String? city;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? language;
  final String? bio;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'phone_number': phoneNumber,
        'country': country,
        'state': state,
        'city': city,
        'gender': gender,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'language': language,
        'bio': bio,
      };
}

class UpdateAvatarRequest {
  const UpdateAvatarRequest({required this.localFilePath});

  final String localFilePath;

  Map<String, dynamic> toJson() => <String, dynamic>{'local_file_path': localFilePath};
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'current_password': currentPassword,
        'new_password': newPassword,
      };
}

class UpdateSettingsRequest {
  const UpdateSettingsRequest({this.language, this.notificationEnabled});

  final String? language;
  final bool? notificationEnabled;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'language': language,
        'notification_enabled': notificationEnabled,
      };
}
