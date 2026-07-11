import '../../domain/entities/child_profile.dart';

class LinkedParentModel {
  const LinkedParentModel({
    required this.parentId,
    required this.fullName,
    required this.email,
    required this.linkStatus,
    this.relationship,
  });

  final String parentId;
  final String fullName;
  final String email;
  final String? relationship;
  final String linkStatus;

  factory LinkedParentModel.fromJson(Map<String, dynamic> json) {
    return LinkedParentModel(
      parentId: json['parent_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      relationship: json['relationship'] as String?,
      linkStatus: json['link_status'] as String? ?? 'linked',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'parent_id': parentId,
        'full_name': fullName,
        'email': email,
        'relationship': relationship,
        'link_status': linkStatus,
      };

  LinkedParent toEntity() {
    return LinkedParent(
      parentId: parentId,
      fullName: fullName,
      email: email,
      relationship: relationship,
      linkStatus: LinkStatus.values.firstWhere(
        (LinkStatus s) => s.name == linkStatus,
        orElse: () => LinkStatus.linked,
      ),
    );
  }
}

/// Wire format for a child profile as returned by the Child API.
///
/// Hand-written [fromJson]/[toJson] — no codegen required.
class ChildProfileModel {
  const ChildProfileModel({
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
  final String? dateOfBirth;
  final String? gender;
  final String? school;
  final String? grade;
  final String? bio;
  final LinkedParentModel? linkedParent;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    final Object? linkedParentRaw = json['linked_parent'];
    return ChildProfileModel(
      childId: json['child_id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      profilePhoto: json['profile_photo'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      school: json['school'] as String?,
      grade: json['grade'] as String?,
      bio: json['bio'] as String?,
      linkedParent: linkedParentRaw == null
          ? null
          : LinkedParentModel.fromJson(
              linkedParentRaw as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'child_id': childId,
        'full_name': fullName,
        'username': username,
        'email': email,
        'profile_photo': profilePhoto,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'school': school,
        'grade': grade,
        'bio': bio,
        'linked_parent': linkedParent?.toJson(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ChildProfile toEntity() {
    return ChildProfile(
      childId: childId,
      fullName: fullName,
      username: username,
      email: email,
      profilePhoto: profilePhoto,
      dateOfBirth:
          dateOfBirth == null ? null : DateTime.tryParse(dateOfBirth!),
      gender: gender,
      school: school,
      grade: grade,
      bio: bio,
      linkedParent: linkedParent?.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
