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
/// Redirect rules (evaluated in order):
/// 1. Session loading → [AppRoutes.splash].
/// 2. Unauthenticated on a protected route → [AppRoutes.login].
/// 3. Authenticated on a public/splash/child-login route → role home.
/// 4. Non-admin attempting any `/admin/*` route → role home.
/// 5. Child attempting parent dashboard → [AppRoutes.childDashboard].
/// 6. Otherwise → no redirect (allow navigation).
///
/// Role → home mapping:
/// - `'admin'`  → [AppRoutes.adminCms]
/// - `'child'`  → [AppRoutes.childDashboard]
/// - `'parent'` → [AppRoutes.dashboard]
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
    // Treat any path that starts with /admin as an admin-only area.
    final bool isAdminRoute = location.startsWith('/admin');

    return session.when(
      data: (SessionStatus status) {
        final bool authenticated = status == SessionStatus.authenticated;

        if (!authenticated) {
          // Session check complete: always leave the splash screen now.
          if (isSplash) return AppRoutes.login;
          // Allow child-login and other public routes while signed out.
          if (isPublicRoute || isChildLogin) return null;
          return AppRoutes.login;
        }

        // Authenticated — determine home screen by role.
        final String role = _ref.read(userRoleProvider);
        final bool isAdmin = _ref.read(isAdminProvider);
        final String homeRoute = switch (role) {
          'child' => AppRoutes.childDashboard,
          _ => AppRoutes.dashboard, // parent (including admin-parents) land on dashboard
        };

        // Keep authenticated users off public / splash / child-login screens.
        if (isPublicRoute || isChildLogin) return homeRoute;

        // Block non-admins from all /admin/* routes.
        // Admin-parents (isAdmin=true) are allowed through even with role='parent'.
        if (isAdminRoute && !isAdmin) return homeRoute;

        // Prevent a child from landing on the parent dashboard.
        if (role == 'child' && location == AppRoutes.dashboard) {
          return AppRoutes.childDashboard;
        }

        return null;
      },
      loading: () => isSplash ? null : AppRoutes.splash,
      error: (_, __) =>
          isPublicRoute || isChildLogin ? null : AppRoutes.login,
    );
  }
}
