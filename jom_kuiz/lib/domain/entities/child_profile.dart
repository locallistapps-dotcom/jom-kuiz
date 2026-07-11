import 'package:equatable/equatable.dart';

import 'education_level.dart';

export 'education_level.dart';

/// Link status between a child account and a parent account.
enum LinkStatus { linked, pending, unlinked }

/// The parent that is linked to a child, as seen from the child's profile.
class LinkedParent extends Equatable {
  const LinkedParent({
    required this.parentId,
    required this.fullName,
    required this.email,
    required this.linkStatus,
    this.relationship,
  });

  final String parentId;
  final String fullName;
  final String email;

  /// e.g. "father", "mother", "guardian"
  final String? relationship;
  final LinkStatus linkStatus;

  @override
  List<Object?> get props =>
      <Object?>[parentId, fullName, email, relationship, linkStatus];
}

/// Core domain representation of a child's profile.
///
/// Combines both the child's identity information (returned during a child
/// login session) and the education-level fields managed by the parent.
class ChildProfile extends Equatable {
  const ChildProfile({
    required this.childId,
    required this.fullName,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.studentId = '',
    this.educationLevel = EducationLevel.primary,
    this.yearGrade = '',
    this.accountStatus = ChildAccountStatus.active,
    this.profilePhoto,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.linkedParent,
  });

  final String childId;
  final String fullName;
  final String username;

  /// 8-digit auto-generated immutable identifier used for child login.
  final String studentId;

  final EducationLevel educationLevel;

  /// Structured year / grade string, e.g. `"Year 3"`, `"Form 1"`, `"Preschool"`.
  final String yearGrade;

  final ChildAccountStatus accountStatus;
  final String? profilePhoto;
  final DateTime? dateOfBirth;

  /// "male", "female", or "other" — kept as a free string.
  final String? gender;
  final String? bio;
  final LinkedParent? linkedParent;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfile copyWith({
    String? fullName,
    String? username,
    String? studentId,
    EducationLevel? educationLevel,
    String? yearGrade,
    ChildAccountStatus? accountStatus,
    String? profilePhoto,
    DateTime? dateOfBirth,
    String? gender,
    String? bio,
    LinkedParent? linkedParent,
  }) {
    return ChildProfile(
      childId: childId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      studentId: studentId ?? this.studentId,
      educationLevel: educationLevel ?? this.educationLevel,
      yearGrade: yearGrade ?? this.yearGrade,
      accountStatus: accountStatus ?? this.accountStatus,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      linkedParent: linkedParent ?? this.linkedParent,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        childId,
        fullName,
        username,
        studentId,
        educationLevel,
        yearGrade,
        accountStatus,
        profilePhoto,
        dateOfBirth,
        gender,
        bio,
        linkedParent,
        createdAt,
        updatedAt,
      ];
}
