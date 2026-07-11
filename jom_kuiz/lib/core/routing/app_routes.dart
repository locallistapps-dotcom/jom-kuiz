/// Centralized route paths and names, so screens/widgets never hardcode
/// route strings inline.
abstract final class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ── Parent ────────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String editProfile = '/parent/edit-profile';
  static const String security = '/parent/security';

  // ── Child ─────────────────────────────────────────────────────────────────
  static const String childDashboard = '/child/dashboard';
  static const String childProfile = '/child/profile';
  static const String childEditProfile = '/child/edit-profile';
  static const String childLinkedParent = '/child/linked-parent';
  static const String childHomework = '/child/homework';
  static const String childHomeworkDetail = '/child/homework/detail';
  static const String childQuiz = '/child/quiz';
  static const String childQuizDetail = '/child/quiz/detail';
  static const String childAchievements = '/child/achievements';

  // ── Route names ───────────────────────────────────────────────────────────
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgotPassword';
  static const String resetPasswordName = 'resetPassword';
  static const String dashboardName = 'dashboard';
  static const String settingsName = 'settings';
  static const String editProfileName = 'editProfile';
  static const String securityName = 'security';
  static const String childDashboardName = 'childDashboard';
  static const String childProfileName = 'childProfile';
  static const String childEditProfileName = 'childEditProfile';
  static const String childLinkedParentName = 'childLinkedParent';
  static const String childHomeworkName = 'childHomework';
  static const String childHomeworkDetailName = 'childHomeworkDetail';
  static const String childQuizName = 'childQuiz';
  static const String childQuizDetailName = 'childQuizDetail';
  static const String childAchievementsName = 'childAchievements';

  /// Routes reachable while signed out. Every other route requires an
  /// authenticated session — see [RouteGuard].
  static const List<String> publicRoutes = <String>[
    splash,
    login,
    register,
    forgotPassword,
    resetPassword,
  ];
}
