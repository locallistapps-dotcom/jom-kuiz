import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/session_status.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';

/// Splash screen shown while [SessionController] checks for a stored login
/// session, a valid JWT, and (if the access token is expired) whether the
/// refresh token can silently renew it.
///
/// Actual navigation happens via [RouteGuard.redirect] reacting to
/// [sessionControllerProvider] -- this screen only needs to render the
/// current state and trigger the provider by watching it.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SessionStatus> session = ref.watch(sessionControllerProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Jom Kuiz', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Learning made fun', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            session.when(
              data: (_) => const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              loading: () => const LoadingWidget(),
              error: (_, __) => AppErrorWidget(
                message: 'Could not check your session',
                onRetry: () => ref.read(sessionControllerProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
