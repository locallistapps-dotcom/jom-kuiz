import 'package:shared_preferences/shared_preferences.dart';

/// Persists remembered login identifiers via [SharedPreferences].
///
/// ONLY non-sensitive convenience data is stored here:
///   - Parent: email address
///   - Child: Student ID + username
///
/// Passwords are NEVER stored. JWTs and refresh tokens are handled by
/// [TokenManager] via [FlutterSecureStorage].
class LoginPreferencesService {
  static const String _parentEmailKey = 'pref_parent_email';
  static const String _childStudentIdKey = 'pref_child_student_id';
  static const String _childUsernameKey = 'pref_child_username';

  // ── Parent email ──────────────────────────────────────────────────────────

  /// Saves [email] so it can be pre-filled on the next login.
  Future<void> saveParentEmail(String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_parentEmailKey, email.trim().toLowerCase());
  }

  /// Returns the last successfully-used parent email, or `null` if none.
  Future<String?> getParentEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentEmailKey);
  }

  // ── Child credentials ─────────────────────────────────────────────────────

  /// Saves [studentId] and [username] so they can be pre-filled on the next
  /// child login. Password is intentionally excluded.
  Future<void> saveChildCredentials({
    required String studentId,
    required String username,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_childStudentIdKey, studentId.trim());
    await prefs.setString(_childUsernameKey, username.trim().toLowerCase());
  }

  /// Returns the last successfully-used child credentials as a record, or
  /// `null` if none have been saved yet.
  Future<({String studentId, String username})?> getChildCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? studentId = prefs.getString(_childStudentIdKey);
    final String? username = prefs.getString(_childUsernameKey);
    if (studentId == null || username == null) return null;
    return (studentId: studentId, username: username);
  }
}
