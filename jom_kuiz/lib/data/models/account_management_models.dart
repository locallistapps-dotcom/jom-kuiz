import '../../domain/entities/education_level.dart';

/// Wire format for a child row as stored in the `children` table.
///
/// Returned by `POST /rpc/create_child`, `POST /rpc/update_child`, and
/// `GET /children`.
class ChildManagementModel {
  const ChildManagementModel({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.fullName,
    required this.username,
    required this.educationLevel,
    required this.yearGrade,
    required this.accountStatus,
    required this.createdAt,
    required this.updatedAt,
    this.profilePhoto,
  });

  final String id;
  final String parentId;
  final String studentId;
  final String fullName;
  final String username;
  final String educationLevel;
  final String yearGrade;
  final String accountStatus;
  final String? profilePhoto;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChildManagementModel.fromJson(Map<String, dynamic> json) =>
      ChildManagementModel(
        id: json['id'] as String,
        parentId: json['parent_id'] as String,
        studentId: json['student_id'] as String,
        fullName: json['full_name'] as String,
        username: json['username'] as String,
        educationLevel: json['education_level'] as String? ?? 'primary',
        yearGrade: json['year_grade'] as String? ?? 'Year 1',
        accountStatus: json['account_status'] as String? ?? 'active',
        profilePhoto: json['profile_photo'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'parent_id': parentId,
        'student_id': studentId,
        'full_name': fullName,
        'username': username,
        'education_level': educationLevel,
        'year_grade': yearGrade,
        'account_status': accountStatus,
        'profile_photo': profilePhoto,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Per-child summary data shown on the Parent Dashboard children list.
///
/// Combines the child's profile with aggregated quiz performance pulled from
/// [PerformanceRemoteDataSource.getRawResultsForChildren].
class ChildCardData {
  const ChildCardData({
    required this.childId,
    required this.studentId,
    required this.fullName,
    required this.username,
    required this.educationLevel,
    required this.yearGrade,
    required this.accountStatus,
    required this.totalQuizzes,
    required this.averageScore,
    required this.latestScore,
    this.profilePhoto,
  });

  final String childId;
  final String studentId;
  final String fullName;
  final String username;
  final EducationLevel educationLevel;
  final String yearGrade;
  final ChildAccountStatus accountStatus;
  final String? profilePhoto;
  final int totalQuizzes;
  final double averageScore;

  /// Percentage of the most recent quiz; -1 if no quizzes taken yet.
  final double latestScore;

  static ChildCardData fromModel(
    ChildManagementModel model, {
    int totalQuizzes = 0,
    double averageScore = 0.0,
    double latestScore = -1.0,
  }) =>
      ChildCardData(
        childId: model.id,
        studentId: model.studentId,
        fullName: model.fullName,
        username: model.username,
        educationLevel: EducationLevelHelper.fromString(model.educationLevel),
        yearGrade: model.yearGrade,
        accountStatus: EducationLevelHelper.statusFromString(model.accountStatus),
        profilePhoto: model.profilePhoto,
        totalQuizzes: totalQuizzes,
        averageScore: averageScore,
        latestScore: latestScore,
      );
}
