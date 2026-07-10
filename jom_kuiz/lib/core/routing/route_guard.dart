import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Decides whether a navigation to [GoRouterState.matchedLocation] should be
/// redirected, based on auth session state.
///
/// Currently a documented pass-through (no redirects) since [SessionManager]
/// / auth state is not implemented yet. Wire this up once login exists:
/// unauthenticated users hitting [AppRoutes.dashboard] or [AppRoutes.settings]
/// should be redirected to [AppRoutes.login], and authenticated users hitting
/// [AppRoutes.login] / [AppRoutes.register] should be redirected to
/// [AppRoutes.dashboard].
class RouteGuard {
  RouteGuard(this._ref);

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    // TODO(auth): read session state via ref and redirect accordingly.
    return null;
  }
}
