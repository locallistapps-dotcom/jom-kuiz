import '../../domain/entities/child_profile.dart';
import '../../domain/entities/education_level.dart';

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
/// Includes the new Prompt 12 fields: `student_id`, `education_level`,
/// `year_grade`, `account_status`. The old free-text `school` / `grade`
/// fields have been replaced by the structured education fields.
class ChildProfileModel {
  const ChildProfileModel({
    required this.childId,
    required this.fullName,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.studentId = '',
    this.educationLevel = 'primary',
    this.yearGrade = '',
    this.accountStatus = 'active',
    this.profilePhoto,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.linkedParent,
  });

  final String childId;
  final String fullName;
  final String username;
  final String studentId;
  final String educationLevel;
  final String yearGrade;
  final String accountStatus;
  final String? profilePhoto;
  final String? dateOfBirth;
  final String? gender;
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
      studentId: json['student_id'] as String? ?? '',
      educationLevel: json['education_level'] as String? ?? 'primary',
      yearGrade: json['year_grade'] as String? ?? '',
      accountStatus: json['account_status'] as String? ?? 'active',
      profilePhoto: json['profile_photo'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
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
        'student_id': studentId,
        'education_level': educationLevel,
        'year_grade': yearGrade,
        'account_status': accountStatus,
        'profile_photo': profilePhoto,
        'date_of_birth': dateOfBirth,
        'gender': gender,
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
      studentId: studentId,
      educationLevel: EducationLevelHelper.fromString(educationLevel),
      yearGrade: yearGrade,
      accountStatus: EducationLevelHelper.statusFromString(accountStatus),
      profilePhoto: profilePhoto,
      dateOfBirth: dateOfBirth == null ? null : DateTime.tryParse(dateOfBirth!),
      gender: gender,
      bio: bio,
      linkedParent: linkedParent?.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
