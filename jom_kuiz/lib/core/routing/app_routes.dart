/// Centralized route paths and names, so screens/widgets never hardcode
/// route strings inline.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';

  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String dashboardName = 'dashboard';
  static const String settingsName = 'settings';
}
