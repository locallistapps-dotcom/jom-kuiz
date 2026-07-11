/// Official error codes for the Teacher module.
abstract final class TeacherErrorCodes {
  /// The requested teacher profile does not exist on the server.
  static const String teacherNotFound = 'TEACHER-001';

  /// The dashboard data could not be retrieved (server-side error).
  static const String dashboardUnavailable = 'TEACHER-002';

  /// The caller is not authorised to access this teacher's data.
  static const String unauthorized = 'TEACHER-003';
}
