import '../../domain/entities/parent_profile.dart';

/// Wire format for a parent profile as returned by the Parent API.
///
/// Hand-written `fromJson`/`toJson` (no `json_serializable` codegen) so this
/// compiles standalone without a `build_runner` step. Field names use
/// snake_case to match the REST/PostgreSQL convention used elsewhere in this
/// project.
class ParentProfileModel {
  const ParentProfileModel({
    required this.parentId,
    required this.fullName,
    required this.email,
    required this.emailVerified,
    required this.accountStatus,
    required this.notificationEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.country,
    this.state,
    this.city,
    this.profilePhoto,
    this.gender,
    this.dateOfBirth,
    this.language = 'en',
    this.timezone,
    this.bio,
  });

  final String parentId;
  final String fullName;
  final String email;
  final bool emailVerified;
  final String accountStatus;
  final bool notificationEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? phoneNumber;
  final String? country;
  final String? state;
  final String? city;
  final String? profilePhoto;
  final String? gender;
  final DateTime? dateOfBirth;
  final String language;
  final String? timezone;
  final String? bio;

  factory ParentProfileModel.fromJson(Map<String, dynamic> json) {
    return ParentProfileModel(
      parentId: json['parent_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool? ?? false,
      accountStatus: json['account_status'] as String? ?? 'active',
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      phoneNumber: json['phone_number'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      profilePhoto: json['profile_photo'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      language: json['language'] as String? ?? 'en',
      timezone: json['timezone'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'parent_id': parentId,
      'full_name': fullName,
      'email': email,
      'email_verified': emailVerified,
      'account_status': accountStatus,
      'notification_enabled': notificationEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'phone_number': phoneNumber,
      'country': country,
      'state': state,
      'city': city,
      'profile_photo': profilePhoto,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'language': language,
      'timezone': timezone,
      'bio': bio,
    };
  }

  ParentProfile toEntity() {
    return ParentProfile(
      parentId: parentId,
      fullName: fullName,
      email: email,
      emailVerified: emailVerified,
      accountStatus: AccountStatus.values.firstWhere(
        (AccountStatus status) => status.name == accountStatus,
        orElse: () => AccountStatus.active,
      ),
      notificationEnabled: notificationEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
      phoneNumber: phoneNumber,
      country: country,
      state: state,
      city: city,
      profilePhoto: profilePhoto,
      gender: gender,
      dateOfBirth: dateOfBirth,
      language: language,
      timezone: timezone,
      bio: bio,
    );
  }
}
