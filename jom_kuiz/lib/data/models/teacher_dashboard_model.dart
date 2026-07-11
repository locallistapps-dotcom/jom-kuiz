import '../../domain/entities/teacher_dashboard.dart';

// ── TeacherProfileModel ───────────────────────────────────────────────────────

class TeacherProfileModel {
  const TeacherProfileModel({
    required this.teacherId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.subject,
    this.profilePhoto,
    this.employeeId,
    this.phoneNumber,
  });

  final String teacherId;
  final String fullName;
  final String username;
  final String email;
  final String subject;
  final String? profilePhoto;
  final String? employeeId;
  final String? phoneNumber;

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) =>
      TeacherProfileModel(
        teacherId: json['teacher_id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        profilePhoto: json['profile_photo'] as String?,
        employeeId: json['employee_id'] as String?,
        phoneNumber: json['phone_number'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'teacher_id': teacherId,
        'full_name': fullName,
        'username': username,
        'email': email,
        'subject': subject,
        if (profilePhoto != null) 'profile_photo': profilePhoto,
        if (employeeId != null) 'employee_id': employeeId,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };

  TeacherProfile toEntity() => TeacherProfile(
        teacherId: teacherId,
        fullName: fullName,
        username: username,
        email: email,
        subject: subject,
        profilePhoto: profilePhoto,
        employeeId: employeeId,
        phoneNumber: phoneNumber,
      );
}

// ── SchoolInfoModel ───────────────────────────────────────────────────────────

class SchoolInfoModel {
  const SchoolInfoModel({
    required this.schoolName,
    this.schoolAddress,
    this.schoolType,
    this.academicYear,
  });

  final String schoolName;
  final String? schoolAddress;
  final String? schoolType;
  final String? academicYear;

  factory SchoolInfoModel.fromJson(Map<String, dynamic> json) =>
      SchoolInfoModel(
        schoolName: json['school_name'] as String? ?? '',
        schoolAddress: json['school_address'] as String?,
        schoolType: json['school_type'] as String?,
        academicYear: json['academic_year'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'school_name': schoolName,
        if (schoolAddress != null) 'school_address': schoolAddress,
        if (schoolType != null) 'school_type': schoolType,
        if (academicYear != null) 'academic_year': academicYear,
      };

  SchoolInfo toEntity() => SchoolInfo(
        schoolName: schoolName,
        schoolAddress: schoolAddress,
        schoolType: schoolType,
        academicYear: academicYear,
      );
}

// ── TeacherClassModel ─────────────────────────────────────────────────────────

class TeacherClassModel {
  const TeacherClassModel({
    required this.classId,
    required this.name,
    required this.subject,
    required this.studentCount,
    this.gradeLevel,
  });

  final String classId;
  final String name;
  final String subject;
  final int studentCount;
  final String? gradeLevel;

  factory TeacherClassModel.fromJson(Map<String, dynamic> json) =>
      TeacherClassModel(
        classId: json['class_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        studentCount: json['student_count'] as int? ?? 0,
        gradeLevel: json['grade_level'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'class_id': classId,
        'name': name,
        'subject': subject,
        'student_count': studentCount,
        if (gradeLevel != null) 'grade_level': gradeLevel,
      };

  TeacherClass toEntity() => TeacherClass(
        classId: classId,
        name: name,
        subject: subject,
        studentCount: studentCount,
        gradeLevel: gradeLevel,
      );
}

// ── ScheduleItemModel ─────────────────────────────────────────────────────────

class ScheduleItemModel {
  const ScheduleItemModel({
    required this.time,
    required this.subject,
    required this.className,
    this.room,
  });

  final String time;
  final String subject;
  final String className;
  final String? room;

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) =>
      ScheduleItemModel(
        time: json['time'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        className: json['class_name'] as String? ?? '',
        room: json['room'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'time': time,
        'subject': subject,
        'class_name': className,
        if (room != null) 'room': room,
      };

  ScheduleItem toEntity() => ScheduleItem(
        time: time,
        subject: subject,
        className: className,
        room: room,
      );
}

// ── RecentActivityModel ───────────────────────────────────────────────────────

class RecentActivityModel {
  const RecentActivityModel({
    required this.type,
    required this.description,
    required this.timestamp,
    this.relatedId,
  });

  final String type;
  final String description;
  final String timestamp;
  final String? relatedId;

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) =>
      RecentActivityModel(
        type: json['type'] as String? ?? 'other',
        description: json['description'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        relatedId: json['related_id'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'description': description,
        'timestamp': timestamp,
        if (relatedId != null) 'related_id': relatedId,
      };

  RecentActivity toEntity() => RecentActivity(
        type: ActivityType.values.firstWhere(
          (ActivityType t) => t.name == type,
          orElse: () => ActivityType.other,
        ),
        description: description,
        timestamp: DateTime.tryParse(timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0),
        relatedId: relatedId,
      );
}

// ── TeacherDashboardModel ─────────────────────────────────────────────────────

/// Root DTO for the teacher dashboard API response.
class TeacherDashboardModel {
  const TeacherDashboardModel({
    required this.profile,
    required this.school,
    required this.assignedClasses,
    required this.todaySchedule,
    required this.recentActivities,
  });

  final TeacherProfileModel profile;
  final SchoolInfoModel school;
  final List<TeacherClassModel> assignedClasses;
  final List<ScheduleItemModel> todaySchedule;
  final List<RecentActivityModel> recentActivities;

  factory TeacherDashboardModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> classes =
        json['assigned_classes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> schedule =
        json['today_schedule'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> activities =
        json['recent_activities'] as List<dynamic>? ?? <dynamic>[];

    return TeacherDashboardModel(
      profile: TeacherProfileModel.fromJson(
        json['profile'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      school: SchoolInfoModel.fromJson(
        json['school'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      assignedClasses: classes
          .map((dynamic e) =>
              TeacherClassModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      todaySchedule: schedule
          .map((dynamic e) =>
              ScheduleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivities: activities
          .map((dynamic e) =>
              RecentActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'profile': profile.toJson(),
        'school': school.toJson(),
        'assigned_classes':
            assignedClasses.map((TeacherClassModel c) => c.toJson()).toList(),
        'today_schedule':
            todaySchedule.map((ScheduleItemModel s) => s.toJson()).toList(),
        'recent_activities':
            recentActivities.map((RecentActivityModel a) => a.toJson()).toList(),
      };

  TeacherDashboard toEntity() => TeacherDashboard(
        profile: profile.toEntity(),
        school: school.toEntity(),
        assignedClasses:
            assignedClasses.map((TeacherClassModel c) => c.toEntity()).toList(),
        todaySchedule:
            todaySchedule.map((ScheduleItemModel s) => s.toEntity()).toList(),
        recentActivities: recentActivities
            .map((RecentActivityModel a) => a.toEntity())
            .toList(),
      );
}
