import 'package:equatable/equatable.dart';

// ── Teacher Profile ───────────────────────────────────────────────────────────

/// Immutable snapshot of the logged-in teacher's own profile.
class TeacherProfile extends Equatable {
  const TeacherProfile({
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

  /// Primary subject the teacher is qualified to teach.
  final String subject;

  final String? profilePhoto;
  final String? employeeId;
  final String? phoneNumber;

  @override
  List<Object?> get props => <Object?>[
        teacherId,
        fullName,
        username,
        email,
        subject,
        profilePhoto,
        employeeId,
        phoneNumber,
      ];
}

// ── School Information ────────────────────────────────────────────────────────

/// Metadata about the school the teacher is attached to.
class SchoolInfo extends Equatable {
  const SchoolInfo({
    required this.schoolName,
    this.schoolAddress,
    this.schoolType,
    this.academicYear,
  });

  final String schoolName;
  final String? schoolAddress;
  final String? schoolType;
  final String? academicYear;

  @override
  List<Object?> get props => <Object?>[
        schoolName,
        schoolAddress,
        schoolType,
        academicYear,
      ];
}

// ── Assigned Class ────────────────────────────────────────────────────────────

/// A single class the teacher is assigned to teach.
class TeacherClass extends Equatable {
  const TeacherClass({
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

  @override
  List<Object?> get props =>
      <Object?>[classId, name, subject, studentCount, gradeLevel];
}

// ── Schedule ──────────────────────────────────────────────────────────────────

/// One entry in today's timetable for the teacher.
class ScheduleItem extends Equatable {
  const ScheduleItem({
    required this.time,
    required this.subject,
    required this.className,
    this.room,
  });

  /// Display time in "HH:mm" format, e.g. "08:00".
  final String time;
  final String subject;
  final String className;
  final String? room;

  @override
  List<Object?> get props => <Object?>[time, subject, className, room];
}

// ── Recent Activity ───────────────────────────────────────────────────────────

enum ActivityType { homework, quiz, announcement, attendance, other }

/// A single activity record shown in the "Recent Activities" feed.
class RecentActivity extends Equatable {
  const RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
    this.relatedId,
  });

  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final String? relatedId;

  @override
  List<Object?> get props =>
      <Object?>[type, description, timestamp, relatedId];
}

// ── Aggregate Dashboard ───────────────────────────────────────────────────────

/// Aggregated view model for the Teacher Dashboard screen.
///
/// Combines [profile], [school], [assignedClasses], [todaySchedule], and
/// [recentActivities] into a single object so the controller only needs one
/// API call to power the entire dashboard.
class TeacherDashboard extends Equatable {
  const TeacherDashboard({
    required this.profile,
    required this.school,
    required this.assignedClasses,
    required this.todaySchedule,
    required this.recentActivities,
  });

  final TeacherProfile profile;
  final SchoolInfo school;
  final List<TeacherClass> assignedClasses;
  final List<ScheduleItem> todaySchedule;
  final List<RecentActivity> recentActivities;

  /// Derived total across all assigned classes.
  int get totalStudents =>
      assignedClasses.fold(0, (int sum, TeacherClass c) => sum + c.studentCount);

  @override
  List<Object?> get props => <Object?>[
        profile,
        school,
        assignedClasses,
        todaySchedule,
        recentActivities,
      ];
}
