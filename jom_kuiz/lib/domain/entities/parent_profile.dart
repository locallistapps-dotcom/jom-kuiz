import 'package:equatable/equatable.dart';

/// Account status for a parent record.
enum AccountStatus { active, suspended, deactivated }

/// Core domain representation of a parent's profile.
///
/// Mirrors the database-ready field set from the Parent module spec. Fields
/// belonging to other modules (children, subscription, wallet, referral,
/// analytics) are deliberately absent -- they will reference [parentId]
/// once those modules exist, never inline here.
class ParentProfile extends Equatable {
  const ParentProfile({
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
  final AccountStatus accountStatus;
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

  ParentProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? country,
    String? state,
    String? city,
    String? profilePhoto,
    String? gender,
    DateTime? dateOfBirth,
    String? language,
    String? timezone,
    String? bio,
    bool? notificationEnabled,
  }) {
    return ParentProfile(
      parentId: parentId,
      fullName: fullName ?? this.fullName,
      email: email,
      emailVerified: emailVerified,
      accountStatus: accountStatus,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      bio: bio ?? this.bio,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        parentId,
        fullName,
        email,
        emailVerified,
        accountStatus,
        notificationEnabled,
        createdAt,
        updatedAt,
        phoneNumber,
        country,
        state,
        city,
        profilePhoto,
        gender,
        dateOfBirth,
        language,
        timezone,
        bio,
      ];
}
