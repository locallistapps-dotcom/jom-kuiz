import 'package:equatable/equatable.dart';

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
/// Linked-parent information is embedded for display convenience.
/// Fields belonging to other modules (quiz engine, wallet, etc.) are absent
/// and will reference [childId] once those modules exist.
class ChildProfile extends Equatable {
  const ChildProfile({
    required this.childId,
    required this.fullName,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.profilePhoto,
    this.dateOfBirth,
    this.gender,
    this.school,
    this.grade,
    this.bio,
    this.linkedParent,
  });

  final String childId;
  final String fullName;
  final String username;
  final String? email;
  final String? profilePhoto;
  final DateTime? dateOfBirth;

  /// "male", "female", or "other" — kept as a free string to avoid
  /// breaking changes if the server extends the set later.
  final String? gender;
  final String? school;
  final String? grade;
  final String? bio;
  final LinkedParent? linkedParent;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfile copyWith({
    String? fullName,
    String? username,
    String? email,
    String? profilePhoto,
    DateTime? dateOfBirth,
    String? gender,
    String? school,
    String? grade,
    String? bio,
    LinkedParent? linkedParent,
  }) {
    return ChildProfile(
      childId: childId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      school: school ?? this.school,
      grade: grade ?? this.grade,
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
        email,
        profilePhoto,
        dateOfBirth,
        gender,
        school,
        grade,
        bio,
        linkedParent,
        createdAt,
        updatedAt,
      ];
}
