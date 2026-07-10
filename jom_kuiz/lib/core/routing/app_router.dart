import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/controllers/session_controller.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_parent_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/error/not_found_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import 'app_routes.dart';
import 'route_guard.dart';

/// Notifies [GoRouter] to re-evaluate [RouteGuard.redirect] whenever
/// [sessionControllerProvider] changes (e.g. login succeeds, logout
/// completes, silent refresh finishes).
class _SessionRouterRefreshNotifier extends ChangeNotifier {
  _SessionRouterRefreshNotifier(Ref ref) {
    ref.listen(sessionControllerProvider, (_, __) => notifyListeners());
  }
}

/// Provides the app's single [GoRouter] instance.
///
/// Route guarding is delegated to [RouteGuard.redirect] so auth logic stays
/// out of the router's declarative route table. Feature screens beyond
/// Authentication (Dashboard content, Settings content) remain placeholders
/// -- see `presentation/screens/*`.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final RouteGuard routeGuard = RouteGuard(ref);
  final _SessionRouterRefreshNotifier refreshNotifier = _SessionRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: routeGuard.redirect,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterParentScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: AppRoutes.resetPasswordName,
        builder: (context, state) {
          final String? resetToken = state.uri.queryParameters['token'];
          return ResetPasswordScreen(resetToken: resetToken);
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardName,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
