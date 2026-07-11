import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../domain/entities/admin_content.dart';
import '../../controllers/admin_content_controller.dart';

/// Admin CMS hub screen.
///
/// Shows a dashboard overview with module cards that navigate to each
/// management screen. The [AdminContent] panel on the right lists published
/// content items with quick publish / unpublish controls.
class AdminCmsScreen extends ConsumerWidget {
  const AdminCmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Admin CMS'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh content',
            onPressed: () =>
                ref.read(adminContentControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // ── Module grid ────────────────────────────────────────────────────
          Text('Content Modules', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: <Widget>[
              _ModuleCard(
                icon: Icons.menu_book_rounded,
                label: 'Subjects',
                color: colorScheme.primaryContainer,
                iconColor: colorScheme.onPrimaryContainer,
                onTap: () => context.push(AppRoutes.subject),
              ),
              _ModuleCard(
                icon: Icons.calendar_today_rounded,
                label: 'Years',
                color: colorScheme.secondaryContainer,
                iconColor: colorScheme.onSecondaryContainer,
                onTap: () => context.push(AppRoutes.year),
              ),
              _ModuleCard(
                icon: Icons.list_alt_rounded,
                label: 'Chapters',
                color: colorScheme.tertiaryContainer,
                iconColor: colorScheme.onTertiaryContainer,
                onTap: () => context.push(AppRoutes.chapter),
              ),
              _ModuleCard(
                icon: Icons.topic_rounded,
                label: 'Topics',
                color: colorScheme.surfaceContainerHighest,
                iconColor: colorScheme.onSurfaceVariant,
                onTap: () => context.push(AppRoutes.topic),
              ),
              _ModuleCard(
                icon: Icons.quiz_rounded,
                label: 'Question Bank',
                color: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
                onTap: () => context.push(AppRoutes.questionBank),
              ),
              _ModuleCard(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Admin Questions',
                color: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
                badge: 'Admin',
                onTap: () => context.push(AppRoutes.adminQuestions),
              ),
              _ModuleCard(
                icon: Icons.card_membership_rounded,
                label: 'Packages',
                color: const Color(0xFFE8EAF6),
                iconColor: const Color(0xFF3949AB),
                badge: 'Admin',
                onTap: () => context.push(AppRoutes.adminPackages),
              ),
              _ModuleCard(
                icon: Icons.lock_open_rounded,
                label: 'Subject Access',
                color: const Color(0xFFE0F2F1),
                iconColor: const Color(0xFF00695C),
                badge: 'Admin',
                onTap: () => context.push(AppRoutes.adminSubjectAccess),
              ),
              _ModuleCard(
                icon: Icons.receipt_long_rounded,
                label: 'Payments',
                color: const Color(0xFFFCE4EC),
                iconColor: const Color(0xFFC62828),
                badge: 'Admin',
                onTap: () => context.push(AppRoutes.adminPayments),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Published content panel ────────────────────────────────────────
          Row(
            children: <Widget>[
              Text('CMS Content', style: textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Manage'),
                onPressed: () => context.push(AppRoutes.adminContent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ContentPanel(),
        ],
      ),
    );
  }
}

// ── Module card ────────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: iconColor, size: 28),
                  if (badge != null) ...<Widget>[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CMS content panel ──────────────────────────────────────────────────────────

class _ContentPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContent = ref.watch(adminContentControllerProvider);

    return asyncContent.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => _ContentError(
        message: err.toString(),
        onRetry: () =>
            ref.read(adminContentControllerProvider.notifier).refresh(),
      ),
      data: (List<AdminContent> items) {
        if (items.isEmpty) {
          return const _EmptyContent();
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) =>
              _ContentTile(content: items[index]),
        );
      },
    );
  }
}

class _ContentTile extends ConsumerWidget {
  const _ContentTile({required this.content});

  final AdminContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = ref.read(adminContentControllerProvider.notifier);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: _typeIcon(content.type, colorScheme),
        title: Text(content.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_typeLabel(content.type)} · '
          '${content.isPublished ? "Published" : "Draft"}',
          style: TextStyle(
            color: content.isPublished
                ? Colors.green[700]
                : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Switch.adaptive(
          value: content.isPublished,
          onChanged: (bool val) async {
            if (val) {
              await controller.publishContent(
                  contentId: content.contentId);
            } else {
              await controller.unpublishContent(
                  contentId: content.contentId);
            }
          },
        ),
      ),
    );
  }

  Widget _typeIcon(AdminContentType type, ColorScheme cs) {
    final IconData icon;
    switch (type) {
      case AdminContentType.announcement:
        icon = Icons.campaign_rounded;
      case AdminContentType.banner:
        icon = Icons.image_rounded;
      case AdminContentType.lesson:
        icon = Icons.school_rounded;
      case AdminContentType.faq:
        icon = Icons.help_outline_rounded;
    }
    return CircleAvatar(
      backgroundColor: cs.primaryContainer,
      child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
    );
  }

  String _typeLabel(AdminContentType type) {
    switch (type) {
      case AdminContentType.announcement:
        return 'Announcement';
      case AdminContentType.banner:
        return 'Banner';
      case AdminContentType.lesson:
        return 'Lesson';
      case AdminContentType.faq:
        return 'FAQ';
    }
  }
}

class _ContentError extends StatelessWidget {
  const _ContentError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: <Widget>[
            Icon(Icons.inbox_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'No content items yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
