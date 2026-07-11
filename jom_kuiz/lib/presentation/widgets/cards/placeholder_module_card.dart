import 'package:flutter/material.dart';

import '../../../core/extension_points/module_placeholders.dart';

/// A dashboard card reserving space/layout for a not-yet-built module.
///
/// Purely presentational -- carries no data or navigation, so swapping it
/// for the real module widget later is a drop-in replacement.
class PlaceholderModuleCard extends StatelessWidget {
  const PlaceholderModuleCard({required this.module, super.key});

  final PlaceholderModule module;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.hourglass_empty,
                size: 20,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(module.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    module.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
