import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/session_controller.dart';
import '../../widgets/feedback/empty_widget.dart';

/// Placeholder dashboard/home screen shown after login.
///
/// This is where the parent/child module summaries will eventually live --
/// intentionally left empty per project scope for this prompt. Only the
/// Logout action (part of the Authentication module) is wired up.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: const EmptyWidget(
        message: 'Your dashboard will appear here once modules are added.',
        icon: Icons.dashboard_outlined,
      ),
    );
  }
}
