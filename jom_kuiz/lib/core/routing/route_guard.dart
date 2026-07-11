import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/session_status.dart';
import '../../presentation/controllers/session_controller.dart';
import '../../presentation/providers/child_providers.dart';
import 'app_routes.dart';

/// Decides whether a navigation should be redirected, based on session state
/// and user role.
///
/// - While the session check is in flight → Splash.
/// - Unauthenticated user on a protected route → Login.
/// - Authenticated **parent** on a public/splash route → /dashboard.
/// - Authenticated **child** on a public/splash route → /child/dashboard.
/// - Authenticated user already on the correct home screen → no redirect.
class RouteGuard {
  RouteGuard(this._ref);

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final AsyncValue<SessionStatus> session =
        _ref.read(sessionControllerProvider);
    final String location = state.matchedLocation;
    final bool isPublicRoute = AppRoutes.publicRoutes.contains(location);
    final bool isSplash = location == AppRoutes.splash;
    final bool isChildLogin = location == AppRoutes.childLogin;

    return session.when(
      data: (SessionStatus status) {
        final bool authenticated = status == SessionStatus.authenticated;

        if (!authenticated) {
          // Always allow child-login and public routes.
          if (isPublicRoute || isChildLogin) return null;
          return AppRoutes.login;
        }

        // Authenticated — determine the home screen by role.
        final String role = _ref.read(userRoleProvider);
        final String homeRoute = role == 'child'
            ? AppRoutes.childDashboard
            : AppRoutes.dashboard;

        // Keep authenticated users out of public / splash / child-login screens.
        if (isPublicRoute || isChildLogin) {
          return homeRoute;
        }

        // Prevent a child from accidentally landing on the parent dashboard.
        if (role == 'child' && location == AppRoutes.dashboard) {
          return AppRoutes.childDashboard;
        }

        return null;
      },
      loading: () => isSplash ? null : AppRoutes.splash,
      error: (_, __) => isPublicRoute || isChildLogin ? null : AppRoutes.login,
    );
  }
}
