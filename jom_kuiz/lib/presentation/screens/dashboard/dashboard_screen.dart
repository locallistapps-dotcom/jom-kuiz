import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/feedback/empty_widget.dart';

/// Placeholder dashboard/home screen shown after login.
///
/// This is where the parent/child module summaries will eventually live --
/// intentionally left empty per project scope for this prompt.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
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
