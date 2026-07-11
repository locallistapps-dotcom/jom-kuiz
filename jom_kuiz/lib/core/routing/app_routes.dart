/// Centralized route paths and names, so screens/widgets never hardcode
/// route strings inline.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String editProfile = '/parent/edit-profile';
  static const String security = '/parent/security';

  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgotPassword';
  static const String resetPasswordName = 'resetPassword';
  static const String dashboardName = 'dashboard';
  static const String settingsName = 'settings';
  static const String editProfileName = 'editProfile';
  static const String securityName = 'security';

  /// Routes reachable while signed out. Any other route requires an
  /// authenticated session -- see [RouteGuard].
  static const List<String> publicRoutes = <String>[
    splash,
    login,
    register,
    forgotPassword,
    resetPassword,
  ];
}
