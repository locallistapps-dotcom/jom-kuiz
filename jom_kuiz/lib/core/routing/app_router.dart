import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/controllers/session_controller.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_parent_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/child/achievement_screen.dart';
import '../../presentation/screens/child/child_dashboard_screen.dart';
import '../../presentation/screens/child/child_profile_screen.dart';
import '../../presentation/screens/child/edit_child_profile_screen.dart';
import '../../presentation/screens/child/homework_detail_screen.dart';
import '../../presentation/screens/child/homework_list_screen.dart';
import '../../presentation/screens/child/linked_parent_screen.dart';
import '../../presentation/screens/child/quiz_detail_screen.dart';
import '../../presentation/screens/child/quiz_list_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/error/not_found_screen.dart';
import '../../presentation/screens/parent/edit_profile_screen.dart';
import '../../presentation/screens/parent/security_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import 'app_routes.dart';
import 'route_guard.dart';

/// Notifies [GoRouter] to re-evaluate [RouteGuard.redirect] whenever
/// [sessionControllerProvider] changes (login, logout, silent refresh).
class _SessionRouterRefreshNotifier extends ChangeNotifier {
  _SessionRouterRefreshNotifier(Ref ref) {
    ref.listen(sessionControllerProvider, (_, __) => notifyListeners());
  }
}

/// Provides the app's single [GoRouter] instance.
///
/// Route guarding is delegated to [RouteGuard.redirect] so auth logic stays
/// out of the route table. All routes except [AppRoutes.publicRoutes] require
/// an authenticated session.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final RouteGuard routeGuard = RouteGuard(ref);
  final _SessionRouterRefreshNotifier refreshNotifier =
      _SessionRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: routeGuard.redirect,
    routes: <RouteBase>[
      // ── Auth ───────────────────────────────────────────────────────────────
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
          final String? token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(resetToken: token);
        },
      ),

      // ── Parent ─────────────────────────────────────────────────────────────
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
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRoutes.editProfileName,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        name: AppRoutes.securityName,
        builder: (context, state) => const SecurityScreen(),
      ),

      // ── Child ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.childDashboard,
        name: AppRoutes.childDashboardName,
        builder: (context, state) => const ChildDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.childProfile,
        name: AppRoutes.childProfileName,
        builder: (context, state) => const ChildProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.childEditProfile,
        name: AppRoutes.childEditProfileName,
        builder: (context, state) => const EditChildProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.childLinkedParent,
        name: AppRoutes.childLinkedParentName,
        builder: (context, state) => const LinkedParentScreen(),
      ),
      GoRoute(
        path: AppRoutes.childHomework,
        name: AppRoutes.childHomeworkName,
        builder: (context, state) => const HomeworkListScreen(),
      ),
      GoRoute(
        path: AppRoutes.childHomeworkDetail,
        name: AppRoutes.childHomeworkDetailName,
        builder: (context, state) => const HomeworkDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.childQuiz,
        name: AppRoutes.childQuizName,
        builder: (context, state) => const QuizListScreen(),
      ),
      GoRoute(
        path: AppRoutes.childQuizDetail,
        name: AppRoutes.childQuizDetailName,
        builder: (context, state) => const QuizDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.childAchievements,
        name: AppRoutes.childAchievementsName,
        builder: (context, state) => const AchievementScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
