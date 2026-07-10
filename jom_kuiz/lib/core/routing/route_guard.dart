import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/session_status.dart';
import '../../presentation/controllers/session_controller.dart';
import 'app_routes.dart';

/// Decides whether a navigation to [GoRouterState.matchedLocation] should be
/// redirected, based on [sessionControllerProvider].
///
/// - While the session check is in flight, everything routes to Splash.
/// - Authenticated users are kept out of auth screens (Login/Register/etc.)
///   and Splash, and sent to Dashboard instead.
/// - Unauthenticated users are kept out of protected routes and sent to
///   Login.
class RouteGuard {
  RouteGuard(this._ref);

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final AsyncValue<SessionStatus> session = _ref.read(sessionControllerProvider);
    final String location = state.matchedLocation;
    final bool isPublicRoute = AppRoutes.publicRoutes.contains(location);
    final bool isSplash = location == AppRoutes.splash;

    return session.when(
      data: (SessionStatus status) {
        final bool authenticated = status == SessionStatus.authenticated;

        if (authenticated && (isPublicRoute)) {
          return AppRoutes.dashboard;
        }
        if (!authenticated && !isPublicRoute) {
          return AppRoutes.login;
        }
        return null;
      },
      loading: () => isSplash ? null : AppRoutes.splash,
      error: (_, __) => isPublicRoute ? null : AppRoutes.login,
    );
  }
}
