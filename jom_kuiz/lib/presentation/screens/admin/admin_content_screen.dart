import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/admin_content.dart';
import '../../controllers/admin_content_controller.dart';
import '../../providers/admin_providers.dart';
import '../../../data/services/storage_service.dart';

/// Full CRUD screen for Admin CMS content items.
///
/// Features:
/// - Type filter chips (All, Announcement, Banner, Lesson, FAQ).
/// - List of content tiles with publish toggle, edit, and delete actions.
/// - FAB to create new content.
/// - Bottom sheet form for create / edit with image picker.
class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() =>
      _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen> {
  AdminContentType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final asyncContent = ref.watch(adminContentControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('CMS Content'),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(adminContentControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // ── Type filter chips ────────────────────────────────────────────
          _TypeFilterBar(
            selected: _typeFilter,
            onSelected: (AdminContentType? t) =>
                setState(() => _typeFilter = t),
          ),
          const Divider(height: 1),
          // ── Content list ─────────────────────────────────────────────────
          Expanded(
            child: asyncContent.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => _ErrorView(
                message: e is Failure ? e.message : e.toString(),
                onRetry: () => ref
                    .read(adminContentControllerProvider.notifier)
                    .refresh(),
              ),
              data: (List<AdminContent> items) {
                final List<AdminContent> filtered = _typeFilter == null
                    ? items
                    : items
                        .where((AdminContent c) => c.type == _typeFilter)
                        .toList();

                if (filtered.isEmpty) {
                  return const _EmptyView();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext ctx, int i) =>
                      _ContentCard(content: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Content'),
        onPressed: () => _showForm(context, null),
      ),
    );
  }

  void _showForm(BuildContext context, AdminContent? editing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ContentFormSheet(editing: editing),
    );
  }
}

// ── Type filter bar ────────────────────────────────────────────────────────────

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.selected, required this.onSelected});

  final AdminContentType? selected;
  final ValueChanged<AdminContentType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Announcement',
            selected: selected == AdminContentType.announcement,
            onTap: () => onSelected(AdminContentType.announcement),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Banner',
            selected: selected == AdminContentType.banner,
            onTap: () => onSelected(AdminContentType.banner),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Lesson',
            selected: selected == AdminContentType.lesson,
            onTap: () => onSelected(AdminContentType.lesson),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'FAQ',
            selected: selected == AdminContentType.faq,
            onTap: () => onSelected(AdminContentType.faq),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

// ── Content card ──────────────────────────────────────────────────────────────

class _ContentCard extends ConsumerWidget {
  const _ContentCard({required this.content});

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _TypeIcon(content.type, colorScheme),
        title: Text(
          content.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_typeLabel(content.type)} · '
              '${content.isPublished ? "Published" : "Draft"}',
              style: TextStyle(
                fontSize: 12,
                color: content.isPublished
                    ? Colors.green[700]
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (content.body.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                content.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Switch.adaptive(
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (String action) async {
                switch (action) {
                  case 'edit':
                    if (context.mounted) {
                      _showEditForm(context, content);
                    }
                  case 'delete':
                    if (context.mounted) {
                      await _confirmDelete(context, ref, content);
                    }
                }
              },
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Edit'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_rounded, color: Colors.red),
                    title: Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditForm(BuildContext context, AdminContent content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ContentFormSheet(editing: content),
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminContent content,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Content'),
        content:
            Text('Delete "${content.title}"? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final Result<void> result = await ref
          .read(adminContentControllerProvider.notifier)
          .deleteContent(contentId: content.contentId);
      if (context.mounted) {
        result.when(
          success: (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content deleted')),
          ),
          failure: (Failure f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message)),
          ),
        );
      }
    }
  }

  Widget _TypeIcon(AdminContentType type, ColorScheme cs) {
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

// ── Error / Empty views ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No content items.\nTap + to create one.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Create / Edit form sheet ───────────────────────────────────────────────────

class _ContentFormSheet extends ConsumerStatefulWidget {
  const _ContentFormSheet({this.editing});

  final AdminContent? editing;

  @override
  ConsumerState<_ContentFormSheet> createState() =>
      _ContentFormSheetState();
}

class _ContentFormSheetState extends ConsumerState<_ContentFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AdminContentType _type;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _imageUrlCtrl;

  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final AdminContent? c = widget.editing;
    _type = c?.type ?? AdminContentType.announcement;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _bodyCtrl = TextEditingController(text: c?.body ?? '');
    _imageUrlCtrl = TextEditingController(text: c?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.editing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: <Widget>[
                    Text(
                      isEditing ? 'Edit Content' : 'New Content',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: <Widget>[
                    // ── Type ─────────────────────────────────────────────
                    _SectionHeader('Content Type'),
                    DropdownButtonFormField<AdminContentType>(
                      value: _type,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: AdminContentType.values
                          .map((AdminContentType t) =>
                              DropdownMenuItem<AdminContentType>(
                                value: t,
                                child: Text(_typeLabel(t)),
                              ))
                          .toList(),
                      onChanged: (AdminContentType? v) {
                        if (v != null) setState(() => _type = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Title ─────────────────────────────────────────────
                    _SectionHeader('Title'),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (String? v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Title is required'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Body ──────────────────────────────────────────────
                    _SectionHeader('Body'),
                    TextFormField(
                      controller: _bodyCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Body / Content',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Image URL ─────────────────────────────────────────
                    _SectionHeader('Image (optional)'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Image URL',
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 40,
                          child: IconButton.outlined(
                            tooltip: 'Pick image from gallery',
                            icon: const Icon(Icons.photo_library_rounded,
                                size: 20),
                            onPressed: _uploading ? null : _pickImage,
                          ),
                        ),
                      ],
                    ),
                    if (_uploading) ...<Widget>[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 24),

                    // ── Submit ────────────────────────────────────────────
                    FilledButton(
                      onPressed: (_saving || _uploading) ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing
                              ? 'Save Changes'
                              : 'Create Content'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      final StorageService storage = ref.read(storageServiceProvider);
      final String url = await storage.uploadImage(
        bucket: 'content-media',
        bytes: bytes,
        fileName: file.name,
      );
      _imageUrlCtrl.text = url;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final controller =
        ref.read(adminContentControllerProvider.notifier);
    final AdminContent? editing = widget.editing;
    final String? imageUrl = _imageUrlCtrl.text.trim().isNotEmpty
        ? _imageUrlCtrl.text.trim()
        : null;

    final Result<AdminContent> result;
    if (editing == null) {
      result = await controller.createContent(
        type: _type,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        imageUrl: imageUrl,
      );
    } else {
      result = await controller.updateContent(
        contentId: editing.contentId,
        type: _type,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        imageUrl: imageUrl,
      );
    }

    setState(() => _saving = false);

    if (mounted) {
      result.when(
        success: (_) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(editing == null
                  ? 'Content created'
                  : 'Content updated'),
            ),
          );
        },
        failure: (Failure f) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message)),
          );
        },
      );
    }
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
