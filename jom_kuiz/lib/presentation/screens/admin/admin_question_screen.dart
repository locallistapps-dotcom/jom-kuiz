import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/web_file_download_stub.dart'
    if (dart.library.html) '../../../core/utils/web_file_download.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../../data/services/admin_question_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/entities/subject.dart';
import '../../../domain/entities/topic.dart';
import '../../../domain/entities/year.dart';
import '../../controllers/admin_question_controller.dart';
import '../../providers/admin_providers.dart';
import '../../providers/admin_question_providers.dart';

/// Full-featured admin question management screen.
///
/// Features:
/// - Cascading dropdowns (Subject → Year → Chapter → Topic) populated from live DB.
/// - Search, sort, type, and difficulty filters (independent of QuestionBankScreen state).
/// - Bulk selection mode with Delete / Activate / Deactivate / Export actions.
/// - Per-card actions: Edit, Duplicate, Preview, Delete, Toggle Active.
/// - Enhanced question form with all fields including 3 new fields.
/// - CSV import via paste dialog; CSV export via copy dialog.
class AdminQuestionScreen extends ConsumerWidget {
  const AdminQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool bulkMode = ref.watch(adminBulkModeProvider);
    final Set<String> selected = ref.watch(adminSelectedQuestionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: bulkMode
            ? Text('${selected.length} selected')
            : const Text('Question Management'),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: bulkMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Exit bulk mode',
                onPressed: () {
                  ref.read(adminBulkModeProvider.notifier).state = false;
                  ref.read(adminSelectedQuestionsProvider.notifier).state =
                      <String>{};
                },
              )
            : null,
        actions: <Widget>[
          if (!bulkMode) ...<Widget>[
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              tooltip: 'Bulk select',
              onPressed: () =>
                  ref.read(adminBulkModeProvider.notifier).state = true,
            ),
            // Download templates dropdown
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_rounded),
              tooltip: 'Download import templates',
              onSelected: (String val) {
                if (val == 'csv') {
                  triggerFileDownload(
                      _csvImportTemplate, 'import_template.csv', 'text/csv');
                } else {
                  triggerFileDownload(
                      AdminQuestionService.jsonImportTemplate,
                      'import_template.json',
                      'application/json');
                }
              },
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'csv',
                  child: ListTile(
                    leading: Icon(Icons.table_chart_rounded),
                    title: Text('CSV Template'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'json',
                  child: ListTile(
                    leading: Icon(Icons.data_object_rounded),
                    title: Text('JSON Template'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.upload_file_rounded),
              tooltip: 'Import CSV',
              onPressed: () => _showCsvImportDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.data_object_rounded),
              tooltip: 'Import JSON',
              onPressed: () => _showJsonImportDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export CSV',
              onPressed: () => _exportCsv(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () => ref
                  .read(adminQuestionControllerProvider.notifier)
                  .refresh(),
            ),
          ],
          if (bulkMode && selected.isNotEmpty) ...<Widget>[
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export selected',
              onPressed: () => _exportCsv(context, ref),
            ),
          ],
        ],
      ),
      body: Column(
        children: <Widget>[
          const _AdminFilterBar(),
          const Divider(height: 1),
          const Expanded(child: _QuestionList()),
          if (bulkMode && selected.isNotEmpty) const _BulkActionBar(),
        ],
      ),
      floatingActionButton: bulkMode
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Question'),
              onPressed: () => _showFormSheet(context, ref, null),
            ),
    );
  }

  static void _showFormSheet(
      BuildContext context, WidgetRef ref, Question? editing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AdminQuestionFormSheet(editing: editing),
    );
  }

  // ── CSV import template ───────────────────────────────────────────────────

  static const String _csvImportTemplate =
      'Subject,Year,Chapter,Topic,Question,QuestionType,'
      'OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Difficulty,'
      'Explanation,ExplanationImageUrl,Reference\n'
      'Matematik,Tahun 1,Nombor Bulat hingga 100,Tambah,'
      'Berapakah 2 + 3?,mcq,4,5,6,7,B,easy,'
      '2 + 3 = 5,,KSSR pg. 10';

  // ── Import dialogs ────────────────────────────────────────────────────────

  static Future<void> _showCsvImportDialog(
      BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) => _FileImportDialog(
        mode: _ImportMode.csv,
        actionLabel: 'Preview',
        onImport: (List<({String name, String content})> files) async {
          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
          if (!context.mounted) return;
          await _showImportPreviewDialog(context, ref, _ImportMode.csv, files);
        },
      ),
    );
  }

  static Future<void> _showJsonImportDialog(
      BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) => _FileImportDialog(
        mode: _ImportMode.json,
        actionLabel: 'Preview',
        onImport: (List<({String name, String content})> files) async {
          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
          if (!context.mounted) return;
          await _showImportPreviewDialog(context, ref, _ImportMode.json, files);
        },
      ),
    );
  }

  /// Opens the import preview dialog (validation dry-run), then on confirm
  /// runs the actual import and shows the summary dialog.
  static Future<void> _showImportPreviewDialog(
    BuildContext context,
    WidgetRef ref,
    _ImportMode mode,
    List<({String name, String content})> files,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) => _ImportPreviewDialog(
        mode: mode,
        files: files,
        onImportConfirmed: () async {
          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
          if (!context.mounted) return;
          final AdminQuestionController controller =
              ref.read(adminQuestionControllerProvider.notifier);
          int totalRows = 0;
          int totalSucceeded = 0;
          int totalSkipped = 0;
          int totalDuplicates = 0;
          int totalFailed = 0;
          final List<String> allErrors = <String>[];
          final List<AdminImportRowResult> allRowResults =
              <AdminImportRowResult>[];
          for (final ({String name, String content}) f in files) {
            final AdminImportSummary s = mode == _ImportMode.csv
                ? await controller.importFromCsv(csvContent: f.content)
                : await controller.importFromJson(jsonContent: f.content);
            totalRows += s.totalRows;
            totalSucceeded += s.succeeded;
            totalSkipped += s.skipped;
            totalDuplicates += s.duplicates;
            totalFailed += s.failed;
            allErrors.addAll(s.errors.map((String e) => '[${f.name}] $e'));
            allRowResults.addAll(s.rowResults);
          }
          if (context.mounted) {
            _showImportSummaryDialog(
              context,
              AdminImportSummary(
                totalRows: totalRows,
                succeeded: totalSucceeded,
                skipped: totalSkipped,
                duplicates: totalDuplicates,
                failed: totalFailed,
                errors: allErrors,
                rowResults: allRowResults,
              ),
            );
          }
        },
      ),
    );
  }

  static void _showImportSummaryDialog(
      BuildContext context, AdminImportSummary summary) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SummaryRow('Total Rows', summary.totalRows.toString()),
            _SummaryRow('Imported', summary.succeeded.toString(),
                color: summary.succeeded > 0 ? Colors.green : null),
            _SummaryRow('Skipped', summary.skipped.toString(),
                color: summary.skipped > 0 ? Colors.orange : null),
            _SummaryRow('Duplicate', summary.duplicates.toString(),
                color: summary.duplicates > 0 ? Colors.orange : null),
            _SummaryRow('Failed', summary.failed.toString(),
                color: summary.failed > 0 ? Colors.red : null),
            if (summary.errors.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text('Errors:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: summary.errors
                        .map((String e) =>
                            Text(e, style: const TextStyle(fontSize: 12)))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          if (summary.rowResults.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download Report'),
              onPressed: () {
                final String csv = AdminQuestionService.generateImportReport(
                    summary.rowResults);
                triggerFileDownload(csv, 'import_report.csv', 'text/csv');
              },
            ),
          if (summary.errors.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Errors'),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: summary.errors.join('\n')));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error report copied to clipboard')),
                );
              },
            ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Export ────────────────────────────────────────────────────────────────

  static Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final String csv =
        await ref.read(adminQuestionControllerProvider.notifier).exportToCsv();
    if (!context.mounted) return;
    final String filename = _buildExportFilename(ref);
    if (kIsWeb) {
      triggerFileDownload(csv, filename, 'text/csv');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded: $filename')),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => _CsvExportDialog(csvContent: csv),
      );
    }
  }

  /// Builds a filename from active filter values, e.g.
  /// `Matematik_Tahun_1_Bab_1_Tambah.csv`. Falls back to
  /// `jom_kuiz_questions.csv` when no filters are active.
  static String _buildExportFilename(WidgetRef ref) {
    final String subjectId = ref.read(adminQSubjectFilterProvider);
    final String yearId = ref.read(adminQYearFilterProvider);
    final String chapterId = ref.read(adminQChapterFilterProvider);
    final String topicId = ref.read(adminQTopicFilterProvider);

    String slug(String s) =>
        s.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').replaceAll(
              RegExp(r'_+$'),
              '',
            );
    final List<String> parts = <String>[];

    if (subjectId.isNotEmpty) {
      final List<Subject>? subjects =
          ref.read(adminSubjectsDropdownProvider).asData?.value;
      final String? name = subjects
          ?.where((Subject s) => s.subjectId == subjectId)
          .map((Subject s) => s.subjectName)
          .firstOrNull;
      if (name != null) parts.add(slug(name));
    }
    if (yearId.isNotEmpty) {
      final List<Year>? years =
          ref.read(adminYearsDropdownProvider).asData?.value;
      final String? name = years
          ?.where((Year y) => y.yearId == yearId)
          .map((Year y) => y.yearName)
          .firstOrNull;
      if (name != null) parts.add(slug(name));
    }
    if (chapterId.isNotEmpty && subjectId.isNotEmpty && yearId.isNotEmpty) {
      final List<Chapter>? chapters = ref
          .read(adminChaptersDropdownProvider(
              (subjectId: subjectId, yearId: yearId)))
          .asData
          ?.value;
      final String? name = chapters
          ?.where((Chapter c) => c.chapterId == chapterId)
          .map((Chapter c) => c.chapterName)
          .firstOrNull;
      if (name != null) parts.add(slug(name));
    }
    if (topicId.isNotEmpty && chapterId.isNotEmpty) {
      final List<Topic>? topics =
          ref.read(adminTopicsDropdownProvider(chapterId)).asData?.value;
      final String? name = topics
          ?.where((Topic t) => t.topicId == topicId)
          .map((Topic t) => t.topicName)
          .firstOrNull;
      if (name != null) parts.add(slug(name));
    }

    return parts.isEmpty ? 'jom_kuiz_questions.csv' : '${parts.join('_')}.csv';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────────

class _AdminFilterBar extends ConsumerStatefulWidget {
  const _AdminFilterBar();

  @override
  ConsumerState<_AdminFilterBar> createState() => _AdminFilterBarState();
}

class _AdminFilterBarState extends ConsumerState<_AdminFilterBar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(
      text: ref.read(adminQSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String subjectId = ref.watch(adminQSubjectFilterProvider);
    final String yearId = ref.watch(adminQYearFilterProvider);
    final String chapterId = ref.watch(adminQChapterFilterProvider);

    final asyncSubjects = ref.watch(adminSubjectsDropdownProvider);
    final asyncYears = ref.watch(adminYearsDropdownProvider);
    final asyncChapters = ref.watch(
      adminChaptersDropdownProvider(
          (subjectId: subjectId, yearId: yearId)),
    );
    final asyncTopics =
        ref.watch(adminTopicsDropdownProvider(chapterId));

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Row 1: Subject + Year
            Row(
              children: <Widget>[
                Expanded(
                  child: _DropdownField<String>(
                    label: 'Subject',
                    value: subjectId.isEmpty ? null : subjectId,
                    items: asyncSubjects.asData?.value
                        .map((Subject s) => DropdownMenuItem<String>(
                              value: s.subjectId,
                              child: Text(s.subjectName,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (String? v) {
                      ref.read(adminQSubjectFilterProvider.notifier).state =
                          v ?? '';
                      ref.read(adminQYearFilterProvider.notifier).state = '';
                      ref.read(adminQChapterFilterProvider.notifier).state = '';
                      ref.read(adminQTopicFilterProvider.notifier).state = '';
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownField<String>(
                    label: 'Year',
                    value: yearId.isEmpty ? null : yearId,
                    items: asyncYears.asData?.value
                        .map((Year y) => DropdownMenuItem<String>(
                              value: y.yearId,
                              child: Text(y.yearName,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (String? v) {
                      ref.read(adminQYearFilterProvider.notifier).state =
                          v ?? '';
                      ref.read(adminQChapterFilterProvider.notifier).state = '';
                      ref.read(adminQTopicFilterProvider.notifier).state = '';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Row 2: Chapter + Topic
            Row(
              children: <Widget>[
                Expanded(
                  child: _DropdownField<String>(
                    label: 'Chapter',
                    value: chapterId.isEmpty ? null : chapterId,
                    items: asyncChapters.asData?.value
                        .map((Chapter c) => DropdownMenuItem<String>(
                              value: c.chapterId,
                              child: Text(c.chapterName,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (String? v) {
                      ref.read(adminQChapterFilterProvider.notifier).state =
                          v ?? '';
                      ref.read(adminQTopicFilterProvider.notifier).state = '';
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownField<String>(
                    label: 'Topic',
                    value: ref.watch(adminQTopicFilterProvider).isEmpty
                        ? null
                        : ref.watch(adminQTopicFilterProvider),
                    items: asyncTopics.asData?.value
                        .map((Topic t) => DropdownMenuItem<String>(
                              value: t.topicId,
                              child: Text(t.topicName,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (String? v) {
                      ref.read(adminQTopicFilterProvider.notifier).state =
                          v ?? '';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Row 3: Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search questions…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(adminQSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (String v) =>
                  ref.read(adminQSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(height: 6),
            // Row 4: Sort + Type chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _SortDropdown(),
                  const SizedBox(width: 8),
                  _TypeChip(label: 'MCQ', value: QuestionType.mcq),
                  const SizedBox(width: 4),
                  _TypeChip(
                      label: 'True/False', value: QuestionType.trueFalse),
                  const SizedBox(width: 4),
                  _TypeChip(
                      label: 'Fill in Blank',
                      value: QuestionType.fillInTheBlank),
                  const SizedBox(width: 8),
                  _DiffChip(
                      label: 'Easy', value: QuestionDifficulty.easy),
                  const SizedBox(width: 4),
                  _DiffChip(
                      label: 'Medium', value: QuestionDifficulty.medium),
                  const SizedBox(width: 4),
                  _DiffChip(
                      label: 'Hard', value: QuestionDifficulty.hard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final allItems = <DropdownMenuItem<T>>[
      DropdownMenuItem<T>(
        value: null,
        child: Text('All $label',
            style: const TextStyle(
                fontStyle: FontStyle.italic, fontSize: 13)),
      ),
      ...?items,
    ];

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: allItems,
      onChanged: onChanged,
    );
  }
}

class _SortDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(adminQSortOrderProvider);
    return DropdownButton<QuestionSortOrder>(
      value: sort,
      isDense: true,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(8),
      items: const <DropdownMenuItem<QuestionSortOrder>>[
        DropdownMenuItem<QuestionSortOrder>(
          value: QuestionSortOrder.hierarchyAsc,
          child: Text('Hierarchy', style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem<QuestionSortOrder>(
          value: QuestionSortOrder.createdAtDesc,
          child: Text('Newest', style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem<QuestionSortOrder>(
          value: QuestionSortOrder.textAsc,
          child: Text('A → Z', style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem<QuestionSortOrder>(
          value: QuestionSortOrder.difficultyAsc,
          child: Text('Easy first', style: TextStyle(fontSize: 13)),
        ),
      ],
      onChanged: (QuestionSortOrder? v) {
        if (v != null) {
          ref.read(adminQSortOrderProvider.notifier).state = v;
        }
      },
    );
  }
}

class _TypeChip extends ConsumerWidget {
  const _TypeChip({required this.label, required this.value});
  final String label;
  final QuestionType value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(adminQTypeFilterProvider) == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        ref.read(adminQTypeFilterProvider.notifier).state =
            selected ? null : value;
      },
    );
  }
}

class _DiffChip extends ConsumerWidget {
  const _DiffChip({required this.label, required this.value});
  final String label;
  final QuestionDifficulty value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(adminQDifficultyFilterProvider) == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        ref.read(adminQDifficultyFilterProvider.notifier).state =
            selected ? null : value;
      },
    );
  }
}

// ── Question list ─────────────────────────────────────────────────────────────

class _QuestionList extends ConsumerWidget {
  const _QuestionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuestions = ref.watch(adminQuestionControllerProvider);

    return asyncQuestions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => _ErrorView(
        message: e is Failure ? e.message : e.toString(),
        onRetry: () =>
            ref.read(adminQuestionControllerProvider.notifier).refresh(),
      ),
      data: (List<Question> questions) {
        if (questions.isEmpty) {
          return const _EmptyView();
        }
        final bool hasMore = ref.watch(adminQHasMoreProvider);
        // Add 1 extra slot for the Load More button when more pages exist.
        final int itemCount = questions.length + (hasMore ? 1 : 0);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: itemCount,
          itemBuilder: (BuildContext context, int index) {
            if (index == questions.length) {
              return _LoadMoreButton(
                onTap: () => ref
                    .read(adminQuestionControllerProvider.notifier)
                    .loadMore(),
              );
            }
            return _QuestionCard(question: questions[index], index: index);
          },
        );
      },
    );
  }
}

// ── Load More button ──────────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.expand_more_rounded),
          label: const Text('Load More'),
          onPressed: onTap,
        ),
      ),
    );
  }
}

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
            FilledButton(
                onPressed: onRetry, child: const Text('Retry')),
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
          const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No questions found.\nAdjust filters or add a new question.',
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

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends ConsumerWidget {
  const _QuestionCard({required this.question, required this.index});
  final Question question;

  /// 0-based position in the current filtered list — displayed as Q{index+1}.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool bulkMode = ref.watch(adminBulkModeProvider);
    final Set<String> selected = ref.watch(adminSelectedQuestionsProvider);
    final bool isSelected = selected.contains(question.questionId);
    final colorScheme = Theme.of(context).colorScheme;
    final String? topicName = ref
        .watch(adminAllTopicsProvider)
        .asData
        ?.value[question.topicId]
        ?.topicName;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: bulkMode
            ? () {
                final notifier =
                    ref.read(adminSelectedQuestionsProvider.notifier);
                final current =
                    Set<String>.from(notifier.state);
                if (isSelected) {
                  current.remove(question.questionId);
                } else {
                  current.add(question.questionId);
                }
                notifier.state = current;
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (bulkMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        final notifier = ref.read(
                            adminSelectedQuestionsProvider.notifier);
                        final current =
                            Set<String>.from(notifier.state);
                        if (isSelected) {
                          current.remove(question.questionId);
                        } else {
                          current.add(question.questionId);
                        }
                        notifier.state = current;
                      },
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Q-number · Type · Difficulty · Topic badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: <Widget>[
                            _Badge(
                              'Q${index + 1}',
                              color: colorScheme.primaryContainer,
                              textColor: colorScheme.onPrimaryContainer,
                            ),
                            _TypeBadge(question.questionType),
                            _DiffBadge(question.difficulty),
                            if (topicName != null)
                              _Badge(
                                topicName,
                                color: colorScheme.secondaryContainer,
                                textColor: colorScheme.onSecondaryContainer,
                              ),
                            if (!question.isActive)
                              _Badge(
                                'Inactive',
                                color: Colors.red[100]!,
                                textColor: Colors.red[800]!,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          question.questionText,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (question.reference != null &&
                            question.reference!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            'Ref: ${question.reference}',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!bulkMode) _CardMenu(question: question, index: index),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMenu extends ConsumerWidget {
  const _CardMenu({required this.question, required this.index});
  final Question question;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminQuestionControllerProvider.notifier);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (String action) async {
        switch (action) {
          case 'edit':
            _showForm(context, ref, question);
          case 'duplicate':
            final Result<Question> r = await controller.duplicateQuestion(
                questionId: question.questionId);
            if (context.mounted) {
              _showSnack(context,
                  r.isSuccess ? 'Question duplicated' : r.failureMessage);
            }
          case 'preview':
            _showPreview(context, question, index + 1);
          case 'toggle':
            await controller.toggleActive(
              questionId: question.questionId,
              isActive: !question.isActive,
            );
          case 'delete':
            final bool? confirm = await _confirmDelete(context);
            if (confirm == true && context.mounted) {
              final Result<void> r = await controller.deleteQuestion(
                  questionId: question.questionId);
              if (context.mounted) {
                _showSnack(context,
                    r.isSuccess ? 'Question deleted' : r.failureMessage);
              }
            }
        }
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_rounded),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy_rounded),
            title: Text('Duplicate'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'preview',
          child: ListTile(
            leading: Icon(Icons.visibility_rounded),
            title: Text('Preview'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle',
          child: ListTile(
            leading: Icon(question.isActive
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded),
            title:
                Text(question.isActive ? 'Deactivate' : 'Activate'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading:
                Icon(Icons.delete_rounded, color: Colors.red),
            title: Text('Delete',
                style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  static void _showForm(
      BuildContext context, WidgetRef ref, Question editing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AdminQuestionFormSheet(editing: editing),
    );
  }

  static void _showPreview(
      BuildContext context, Question q, int questionNumber) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _QuestionPreviewDialog(question: q, questionNumber: questionNumber),
    );
  }

  static Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ── Bulk action bar ────────────────────────────────────────────────────────────

class _BulkActionBar extends ConsumerWidget {
  const _BulkActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> selected = ref.watch(adminSelectedQuestionsProvider);
    final controller = ref.read(adminQuestionControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colorScheme.surfaceContainerHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _BulkButton(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: colorScheme.error,
            onTap: () async {
              final bool? ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete selected?'),
                  content: Text(
                      'Delete ${selected.length} question(s)? This cannot be undone.'),
                  actions: <Widget>[
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await controller.bulkDelete(questionIds: selected);
              }
            },
          ),
          _BulkButton(
            icon: Icons.check_circle_rounded,
            label: 'Activate',
            color: Colors.green,
            onTap: () => controller.bulkSetActive(
                questionIds: selected, isActive: true),
          ),
          _BulkButton(
            icon: Icons.cancel_rounded,
            label: 'Deactivate',
            color: Colors.orange,
            onTap: () => controller.bulkSetActive(
                questionIds: selected, isActive: false),
          ),
        ],
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  const _BulkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color)),
      onPressed: onTap,
    );
  }
}

// ── Badges ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(this.label,
      {required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: textColor,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type);
  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (type) {
      QuestionType.mcq => ('MCQ', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      QuestionType.trueFalse => ('T/F', const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
      QuestionType.fillInTheBlank => ('Fill', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
    };
    return _Badge(label, color: bg, textColor: fg);
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge(this.difficulty);
  final QuestionDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (difficulty) {
      QuestionDifficulty.easy => ('Easy', const Color(0xFFF1F8E9), const Color(0xFF33691E)),
      QuestionDifficulty.medium => ('Medium', const Color(0xFFFFF8E1), const Color(0xFFE65100)),
      QuestionDifficulty.hard => ('Hard', const Color(0xFFFFEBEE), const Color(0xFFB71C1C)),
    };
    return _Badge(label, color: bg, textColor: fg);
  }
}

// ── Question form sheet ────────────────────────────────────────────────────────

/// Add/Edit question form rendered in a bottom sheet.
class AdminQuestionFormSheet extends ConsumerStatefulWidget {
  const AdminQuestionFormSheet({super.key, this.editing});

  /// Non-null when editing an existing question.
  final Question? editing;

  @override
  ConsumerState<AdminQuestionFormSheet> createState() =>
      _AdminQuestionFormSheetState();
}

class _AdminQuestionFormSheetState
    extends ConsumerState<AdminQuestionFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // Hierarchy selectors (local to the form)
  String? _selectedSubjectId;
  String? _selectedYearId;
  String? _selectedChapterId;
  String? _selectedTopicId;

  // Question fields
  late final TextEditingController _questionTextCtrl;
  late final TextEditingController _optionACtrl;
  late final TextEditingController _optionBCtrl;
  late final TextEditingController _optionCCtrl;
  late final TextEditingController _optionDCtrl;
  late final TextEditingController _correctAnswerCtrl;
  late final TextEditingController _explanationCtrl;
  late final TextEditingController _explanationImageCtrl;
  late final TextEditingController _explanationVideoCtrl;
  late final TextEditingController _questionImageCtrl;
  late final TextEditingController _referenceCtrl;

  late QuestionType _questionType;
  late QuestionDifficulty _difficulty;
  late bool _isActive;

  bool _saving = false;
  bool _uploading = false;
  bool _hierarchyResolved = false;

  @override
  void initState() {
    super.initState();
    final Question? q = widget.editing;
    _questionTextCtrl =
        TextEditingController(text: q?.questionText ?? '');
    _optionACtrl = TextEditingController(text: q?.optionA ?? '');
    _optionBCtrl = TextEditingController(text: q?.optionB ?? '');
    _optionCCtrl = TextEditingController(text: q?.optionC ?? '');
    _optionDCtrl = TextEditingController(text: q?.optionD ?? '');
    _correctAnswerCtrl =
        TextEditingController(text: q?.correctAnswer ?? '');
    _explanationCtrl =
        TextEditingController(text: q?.explanation ?? '');
    _explanationImageCtrl =
        TextEditingController(text: q?.explanationImageUrl ?? '');
    _explanationVideoCtrl =
        TextEditingController(text: q?.explanationVideoUrl ?? '');
    _questionImageCtrl =
        TextEditingController(text: q?.questionImageUrl ?? '');
    _referenceCtrl =
        TextEditingController(text: q?.reference ?? '');
    _questionType = q?.questionType ?? QuestionType.mcq;
    _difficulty = q?.difficulty ?? QuestionDifficulty.easy;
    _isActive = q?.isActive ?? true;
  }

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    _correctAnswerCtrl.dispose();
    _explanationCtrl.dispose();
    _explanationImageCtrl.dispose();
    _explanationVideoCtrl.dispose();
    _questionImageCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.editing != null;
    final asyncSubjects = ref.watch(adminSubjectsDropdownProvider);
    final asyncYears = ref.watch(adminYearsDropdownProvider);
    final asyncChapters = ref.watch(adminChaptersDropdownProvider(
        (subjectId: _selectedSubjectId ?? '', yearId: _selectedYearId ?? '')));
    final asyncTopics = ref.watch(
        adminTopicsDropdownProvider(_selectedChapterId ?? ''));

    // ── Auto-resolve Subject/Year/Chapter when editing an existing question ──
    // Fires once via a post-frame callback so we don't setState() during build.
    if (widget.editing != null && !_hierarchyResolved) {
      final Map<String, Topic>? topicMap =
          ref.watch(adminAllTopicsProvider).asData?.value;
      final Map<String, Chapter>? chapterMap =
          ref.watch(adminAllChaptersProvider).asData?.value;
      if (topicMap != null && chapterMap != null) {
        final Topic? topic = topicMap[widget.editing!.topicId];
        if (topic != null) {
          final Chapter? chapter = chapterMap[topic.chapterId];
          if (chapter != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hierarchyResolved = true;
                  _selectedSubjectId = chapter.subjectId;
                  _selectedYearId = chapter.yearId;
                  _selectedChapterId = topic.chapterId;
                  _selectedTopicId = widget.editing!.topicId;
                });
              }
            });
          }
        }
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (_, scrollCtrl) => Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // Drag handle
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
                      isEditing ? 'Edit Question' : 'Add Question',
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
                    // ── Topic selector (cascading) ─────────────────────────
                    const _SectionHeader('Hierarchy'),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _FormDropdown<String>(
                            label: 'Subject',
                            value: _selectedSubjectId,
                            items: asyncSubjects.asData?.value
                                .map((Subject s) => DropdownMenuItem<String>(
                                      value: s.subjectId,
                                      child: Text(s.subjectName,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (String? v) => setState(() {
                              _selectedSubjectId = v;
                              _selectedYearId = null;
                              _selectedChapterId = null;
                              _selectedTopicId = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FormDropdown<String>(
                            label: 'Year',
                            value: _selectedYearId,
                            items: asyncYears.asData?.value
                                .map((Year y) => DropdownMenuItem<String>(
                                      value: y.yearId,
                                      child: Text(y.yearName,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (String? v) => setState(() {
                              _selectedYearId = v;
                              _selectedChapterId = null;
                              _selectedTopicId = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _FormDropdown<String>(
                            label: 'Chapter',
                            value: _selectedChapterId,
                            items: asyncChapters.asData?.value
                                .map((Chapter c) => DropdownMenuItem<String>(
                                      value: c.chapterId,
                                      child: Text(c.chapterName,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (String? v) => setState(() {
                              _selectedChapterId = v;
                              _selectedTopicId = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FormDropdown<String>(
                            label: 'Topic *',
                            value: _selectedTopicId ?? widget.editing?.topicId,
                            items: asyncTopics.asData?.value
                                .map((Topic t) => DropdownMenuItem<String>(
                                      value: t.topicId,
                                      child: Text(t.topicName,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (String? v) =>
                                setState(() => _selectedTopicId = v),
                            validator: (String? v) =>
                                (v == null || v.isEmpty)
                                    ? 'Topic is required'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Question type + difficulty ─────────────────────────
                    const _SectionHeader('Type & Difficulty'),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<QuestionType>(
                            value: _questionType,
                            decoration: const InputDecoration(
                              labelText: 'Question Type',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const <DropdownMenuItem<QuestionType>>[
                              DropdownMenuItem<QuestionType>(
                                value: QuestionType.mcq,
                                child: Text('MCQ'),
                              ),
                              DropdownMenuItem<QuestionType>(
                                value: QuestionType.trueFalse,
                                child: Text('True / False'),
                              ),
                              DropdownMenuItem<QuestionType>(
                                value: QuestionType.fillInTheBlank,
                                child: Text('Fill in Blank'),
                              ),
                            ],
                            onChanged: (QuestionType? v) {
                              if (v != null) {
                                setState(() {
                                  _questionType = v;
                                  _correctAnswerCtrl.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<QuestionDifficulty>(
                            value: _difficulty,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const <DropdownMenuItem<QuestionDifficulty>>[
                              DropdownMenuItem<QuestionDifficulty>(
                                value: QuestionDifficulty.easy,
                                child: Text('Easy'),
                              ),
                              DropdownMenuItem<QuestionDifficulty>(
                                value: QuestionDifficulty.medium,
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem<QuestionDifficulty>(
                                value: QuestionDifficulty.hard,
                                child: Text('Hard'),
                              ),
                            ],
                            onChanged: (QuestionDifficulty? v) {
                              if (v != null) setState(() => _difficulty = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Question content ──────────────────────────────────
                    const _SectionHeader('Question Content'),
                    TextFormField(
                      controller: _questionTextCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Question Text *',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Question text is required'
                              : null,
                    ),
                    const SizedBox(height: 8),
                    _mediaUrlField(
                      ctrl: _questionImageCtrl,
                      label: 'Question Image URL',
                      hint: 'https://...',
                      isVideo: false,
                    ),
                    const SizedBox(height: 16),

                    // ── Options (MCQ only) ────────────────────────────────
                    if (_questionType == QuestionType.mcq) ...<Widget>[
                      const _SectionHeader('Answer Options'),
                      _optionField('Option A *', _optionACtrl,
                          required: true),
                      const SizedBox(height: 8),
                      _optionField('Option B *', _optionBCtrl,
                          required: true),
                      const SizedBox(height: 8),
                      _optionField('Option C', _optionCCtrl),
                      const SizedBox(height: 8),
                      _optionField('Option D', _optionDCtrl),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _correctAnswerCtrl.text.isEmpty
                            ? null
                            : _correctAnswerCtrl.text,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                              value: 'A', child: Text('A')),
                          DropdownMenuItem<String>(
                              value: 'B', child: Text('B')),
                          DropdownMenuItem<String>(
                              value: 'C', child: Text('C')),
                          DropdownMenuItem<String>(
                              value: 'D', child: Text('D')),
                        ],
                        validator: (String? v) =>
                            (v == null || v.isEmpty)
                                ? 'Select the correct option'
                                : null,
                        onChanged: (String? v) {
                          if (v != null) _correctAnswerCtrl.text = v;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── True/False ────────────────────────────────────────
                    if (_questionType == QuestionType.trueFalse) ...<Widget>[
                      const _SectionHeader('Correct Answer'),
                      DropdownButtonFormField<String>(
                        value: _correctAnswerCtrl.text.isEmpty
                            ? null
                            : _correctAnswerCtrl.text,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                              value: 'true', child: Text('True')),
                          DropdownMenuItem<String>(
                              value: 'false', child: Text('False')),
                        ],
                        validator: (String? v) =>
                            (v == null || v.isEmpty)
                                ? 'Select true or false'
                                : null,
                        onChanged: (String? v) {
                          if (v != null) _correctAnswerCtrl.text = v;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Fill in the blank ─────────────────────────────────
                    if (_questionType ==
                        QuestionType.fillInTheBlank) ...<Widget>[
                      const _SectionHeader('Correct Answer'),
                      TextFormField(
                        controller: _correctAnswerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Correct answer is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Explanation ───────────────────────────────────────
                    const _SectionHeader('Explanation (optional)'),
                    TextFormField(
                      controller: _explanationCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Explanation Text',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _mediaUrlField(
                      ctrl: _explanationImageCtrl,
                      label: 'Explanation Image URL',
                      hint: 'https://...',
                      isVideo: false,
                    ),
                    const SizedBox(height: 8),
                    _mediaUrlField(
                      ctrl: _explanationVideoCtrl,
                      label: 'Explanation Video URL',
                      hint: 'https://...',
                      isVideo: true,
                    ),
                    const SizedBox(height: 16),

                    // ── Meta ──────────────────────────────────────────────
                    const _SectionHeader('Meta'),
                    TextFormField(
                      controller: _referenceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reference',
                        hintText: 'e.g. KSSR Semakan, pg. 42',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.editing != null)
                      SwitchListTile.adaptive(
                        title: const Text('Active'),
                        subtitle: const Text(
                            'Inactive questions are hidden from students'),
                        value: _isActive,
                        onChanged: (bool v) =>
                            setState(() => _isActive = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    const SizedBox(height: 24),

                    // ── Submit ────────────────────────────────────────────
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : Text(isEditing
                              ? 'Save Changes'
                              : 'Create Question'),
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

  /// Builds a URL text field with an adjacent gallery picker icon button.
  ///
  /// Tapping the icon opens the device gallery, uploads the selected file to
  /// Supabase Storage, and populates [ctrl] with the returned public URL.
  Widget _mediaUrlField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required bool isVideo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: TextFormField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          height: 40,
          child: IconButton.outlined(
            tooltip: isVideo
                ? 'Pick video from gallery'
                : 'Pick image from gallery',
            icon: Icon(
              isVideo
                  ? Icons.video_library_rounded
                  : Icons.photo_library_rounded,
              size: 20,
            ),
            onPressed: (_uploading || _saving)
                ? null
                : () => _pickMedia(ctrl, isVideo: isVideo),
          ),
        ),
      ],
    );
  }

  /// Opens the device gallery, uploads the selected file, and sets the URL.
  Future<void> _pickMedia(
    TextEditingController ctrl, {
    required bool isVideo,
  }) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(
            source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      final StorageService storage = ref.read(storageServiceProvider);
      final String url = isVideo
          ? await storage.uploadVideo(
              bucket: 'question-media',
              bytes: bytes,
              fileName: file.name,
            )
          : await storage.uploadImage(
              bucket: 'question-media',
              bytes: bytes,
              fileName: file.name,
            );
      ctrl.text = url;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isVideo ? 'Video uploaded' : 'Image uploaded')),
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

  Widget _optionField(String label, TextEditingController ctrl,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required
          ? (String? v) => (v == null || v.trim().isEmpty)
              ? '$label is required for MCQ'
              : null
          : null,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final String? topicId =
        _selectedTopicId ?? widget.editing?.topicId;
    if (topicId == null || topicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a topic')),
      );
      return;
    }

    setState(() => _saving = true);

    final controller = ref.read(adminQuestionControllerProvider.notifier);
    final Question? editing = widget.editing;

    final Result<Question> result;
    if (editing == null) {
      result = await controller.createQuestion(
        topicId: topicId,
        questionText: _questionTextCtrl.text.trim(),
        questionType: _questionType,
        difficulty: _difficulty,
        correctAnswer: _correctAnswerCtrl.text.trim(),
        optionA: _optionACtrl.text.trim().isNotEmpty
            ? _optionACtrl.text.trim()
            : null,
        optionB: _optionBCtrl.text.trim().isNotEmpty
            ? _optionBCtrl.text.trim()
            : null,
        optionC: _optionCCtrl.text.trim().isNotEmpty
            ? _optionCCtrl.text.trim()
            : null,
        optionD: _optionDCtrl.text.trim().isNotEmpty
            ? _optionDCtrl.text.trim()
            : null,
        explanation: _explanationCtrl.text.trim().isNotEmpty
            ? _explanationCtrl.text.trim()
            : null,
        explanationImageUrl:
            _explanationImageCtrl.text.trim().isNotEmpty
                ? _explanationImageCtrl.text.trim()
                : null,
        explanationVideoUrl:
            _explanationVideoCtrl.text.trim().isNotEmpty
                ? _explanationVideoCtrl.text.trim()
                : null,
        questionImageUrl:
            _questionImageCtrl.text.trim().isNotEmpty
                ? _questionImageCtrl.text.trim()
                : null,
        reference: _referenceCtrl.text.trim().isNotEmpty
            ? _referenceCtrl.text.trim()
            : null,
      );
    } else {
      result = await controller.updateQuestion(
        questionId: editing.questionId,
        topicId: topicId,
        questionText: _questionTextCtrl.text.trim(),
        questionType: _questionType,
        difficulty: _difficulty,
        correctAnswer: _correctAnswerCtrl.text.trim(),
        isActive: _isActive,
        optionA: _optionACtrl.text.trim().isNotEmpty
            ? _optionACtrl.text.trim()
            : null,
        optionB: _optionBCtrl.text.trim().isNotEmpty
            ? _optionBCtrl.text.trim()
            : null,
        optionC: _optionCCtrl.text.trim().isNotEmpty
            ? _optionCCtrl.text.trim()
            : null,
        optionD: _optionDCtrl.text.trim().isNotEmpty
            ? _optionDCtrl.text.trim()
            : null,
        explanation: _explanationCtrl.text.trim().isNotEmpty
            ? _explanationCtrl.text.trim()
            : null,
        explanationImageUrl:
            _explanationImageCtrl.text.trim().isNotEmpty
                ? _explanationImageCtrl.text.trim()
                : null,
        explanationVideoUrl:
            _explanationVideoCtrl.text.trim().isNotEmpty
                ? _explanationVideoCtrl.text.trim()
                : null,
        questionImageUrl:
            _questionImageCtrl.text.trim().isNotEmpty
                ? _questionImageCtrl.text.trim()
                : null,
        reference: _referenceCtrl.text.trim().isNotEmpty
            ? _referenceCtrl.text.trim()
            : null,
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
                    ? 'Question created'
                    : 'Question updated')),
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
}

class _FormDropdown<T> extends StatelessWidget {
  const _FormDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      ),
      items: <DropdownMenuItem<T>>[
        DropdownMenuItem<T>(
            value: null,
            child: Text(
              'Select…',
              style: const TextStyle(
                  fontStyle: FontStyle.italic, fontSize: 13),
            )),
        ...?items,
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

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

// ── Preview dialog ────────────────────────────────────────────────────────────

class _QuestionPreviewDialog extends ConsumerWidget {
  const _QuestionPreviewDialog(
      {required this.question, required this.questionNumber});
  final Question question;

  /// 1-based display number shown in the title area.
  final int questionNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final String? topicName = ref
        .watch(adminAllTopicsProvider)
        .asData
        ?.value[question.topicId]
        ?.topicName;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Badge(
                  'Q$questionNumber',
                  color: colorScheme.primaryContainer,
                  textColor: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                _TypeBadge(question.questionType),
                const SizedBox(width: 8),
                _DiffBadge(question.difficulty),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: Navigator.of(context).pop,
                ),
              ],
            ),
            if (topicName != null) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(Icons.topic_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    topicName,
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (question.questionImageUrl != null &&
                question.questionImageUrl!.isNotEmpty) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  question.questionImageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(question.questionText,
                style: textTheme.titleMedium),
            const SizedBox(height: 16),
            if (question.questionType == QuestionType.mcq) ...<Widget>[
              ...<Widget?>[
                question.optionA != null
                    ? _OptionTile(
                        label: 'A', text: question.optionA!,
                        correct: question.correctAnswer == 'A')
                    : null,
                question.optionB != null
                    ? _OptionTile(
                        label: 'B', text: question.optionB!,
                        correct: question.correctAnswer == 'B')
                    : null,
                question.optionC != null
                    ? _OptionTile(
                        label: 'C', text: question.optionC!,
                        correct: question.correctAnswer == 'C')
                    : null,
                question.optionD != null
                    ? _OptionTile(
                        label: 'D', text: question.optionD!,
                        correct: question.correctAnswer == 'D')
                    : null,
              ].whereType<Widget>().toList(),
            ],
            if (question.questionType == QuestionType.trueFalse) ...<Widget>[
              _OptionTile(
                  label: 'True',
                  text: 'True',
                  correct: question.correctAnswer == 'true'),
              _OptionTile(
                  label: 'False',
                  text: 'False',
                  correct: question.correctAnswer == 'false'),
            ],
            if (question.questionType ==
                QuestionType.fillInTheBlank) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text('Answer: ${question.correctAnswer}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
              ),
            ],
            if (question.explanation != null &&
                question.explanation!.isNotEmpty) ...<Widget>[
              const Divider(height: 24),
              Text('Explanation',
                  style: textTheme.labelLarge
                      ?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: 4),
              Text(question.explanation!),
            ],
            if (question.reference != null &&
                question.reference!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text('Ref: ${question.reference}',
                  style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.label, required this.text, required this.correct});
  final String label;
  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: correct ? Colors.green[50] : null,
          border: Border.all(
              color: correct ? Colors.green : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 12,
              backgroundColor:
                  correct ? Colors.green : Colors.grey[200],
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: correct ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
            if (correct)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Import mode ───────────────────────────────────────────────────────────────

enum _ImportMode { csv, json }

// ── File import dialog ────────────────────────────────────────────────────────

/// Unified file-picker import dialog supporting CSV and JSON batch import
/// with a progress indicator and a template download shortcut.
class _FileImportDialog extends StatefulWidget {
  const _FileImportDialog({
    required this.mode,
    required this.onImport,
    this.actionLabel = 'Import',
  });

  final _ImportMode mode;

  /// Label shown on the primary action button (e.g. 'Preview' or 'Import').
  final String actionLabel;

  /// Invoked when the user taps the action button. The callback receives the
  /// decoded file contents and is responsible for closing [dialogContext] and
  /// showing any result dialogs afterward.
  final Future<void> Function(List<({String name, String content})> files)
      onImport;

  @override
  State<_FileImportDialog> createState() => _FileImportDialogState();
}

class _FileImportDialogState extends State<_FileImportDialog> {
  List<PlatformFile> _selectedFiles = <PlatformFile>[];
  bool _importing = false;
  String _progressMsg = '';

  bool get _isCsv => widget.mode == _ImportMode.csv;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _isCsv ? 'Import Questions from CSV' : 'Import Questions from JSON'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Template download
            OutlinedButton.icon(
              icon: const Icon(Icons.file_download_rounded, size: 18),
              label: Text('Download ${_isCsv ? "CSV" : "JSON"} Template'),
              onPressed: () {
                if (_isCsv) {
                  triggerFileDownload(
                    AdminQuestionScreen._csvImportTemplate,
                    'import_template.csv',
                    'text/csv',
                  );
                } else {
                  triggerFileDownload(
                    AdminQuestionService.jsonImportTemplate,
                    'import_template.json',
                    'application/json',
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // File pick button
            FilledButton.icon(
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: Text(
                  'Pick ${_isCsv ? "CSV" : "JSON"} Files (multiple OK)'),
              onPressed: _importing ? null : _pickFiles,
            ),
            // Selected files list
            if (_selectedFiles.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext _, int i) {
                    final PlatformFile f = _selectedFiles[i];
                    return ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.description_rounded, size: 18),
                      title: Text(f.name,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(_formatBytes(f.size)),
                      trailing: _importing
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () =>
                                  setState(() => _selectedFiles.removeAt(i)),
                            ),
                    );
                  },
                ),
              ),
            ],
            // Progress
            if (_importing) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              Text(_progressMsg, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _importing ? null : Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_selectedFiles.isEmpty || _importing) ? null : _doImport,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>[_isCsv ? 'csv' : 'json'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      setState(() => _selectedFiles = result.files);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick files: $e')),
        );
      }
    }
  }

  Future<void> _doImport() async {
    if (!mounted) return;
    setState(() {
      _importing = true;
      _progressMsg = 'Processing ${_selectedFiles.length} file(s)…';
    });
    try {
      final List<({String name, String content})> files =
          <({String name, String content})>[];
      for (final PlatformFile f in _selectedFiles) {
        final Uint8List? bytes = f.bytes;
        if (bytes == null) continue;
        try {
          files.add((name: f.name, content: utf8.decode(bytes)));
        } catch (_) {
          files.add((name: f.name, content: String.fromCharCodes(bytes)));
        }
      }
      await widget.onImport(files);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

// ── Import preview dialog ─────────────────────────────────────────────────────

/// Shows a dry-run validation of a CSV/JSON import before anything is written
/// to the database. The user can review the row counts (new, duplicate,
/// invalid) and then confirm or cancel the actual import.
class _ImportPreviewDialog extends ConsumerStatefulWidget {
  const _ImportPreviewDialog({
    required this.mode,
    required this.files,
    required this.onImportConfirmed,
  });

  final _ImportMode mode;
  final List<({String name, String content})> files;

  /// Called when the user clicks Import in this dialog. The implementation
  /// should close [dialogCtx] and run the actual import.
  final Future<void> Function() onImportConfirmed;

  @override
  ConsumerState<_ImportPreviewDialog> createState() =>
      _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends ConsumerState<_ImportPreviewDialog> {
  bool _loading = true;
  bool _importing = false;
  AdminImportPreview? _preview;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final AdminQuestionController controller =
          ref.read(adminQuestionControllerProvider.notifier);
      final ({String name, String content}) f = widget.files.first;
      final AdminImportPreview preview = widget.mode == _ImportMode.csv
          ? await controller.previewFromCsv(
              fileName: f.name, csvContent: f.content)
          : await controller.previewFromJson(
              fileName: f.name, jsonContent: f.content);
      if (mounted) setState(() { _preview = preview; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMsg = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Preview'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Validating file…'),
                  ],
                ),
              )
            : _errorMsg != null
                ? Text('Error: $_errorMsg',
                    style: const TextStyle(color: Colors.red))
                : _buildContent(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _importing ? null : Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        if (!_loading && _errorMsg == null)
          FilledButton(
            onPressed: (_importing || (_preview?.newQuestions ?? 0) == 0)
                ? null
                : _doImport,
            child: _importing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Import'),
          ),
      ],
    );
  }

  Widget _buildContent() {
    final AdminImportPreview p = _preview!;
    final bool hasErrors = p.validationErrors.isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PreviewRow('File', p.fileName),
          if (p.subjects.isNotEmpty)
            _PreviewRow('Subject', p.subjects.join(', ')),
          if (p.years.isNotEmpty) _PreviewRow('Year', p.years.join(', ')),
          if (p.chapters.isNotEmpty)
            _PreviewRow('Chapter', p.chapters.join(', ')),
          if (p.topics.isNotEmpty) _PreviewRow('Topic', p.topics.join(', ')),
          const Divider(height: 20),
          _PreviewRow('Rows Found', p.rowsFound.toString()),
          _PreviewRow(
            'New Questions',
            p.newQuestions.toString(),
            color: p.newQuestions > 0 ? Colors.green[700] : null,
          ),
          _PreviewRow(
            'Duplicate Questions',
            p.duplicates.toString(),
            color: p.duplicates > 0 ? Colors.orange[700] : null,
          ),
          _PreviewRow(
            'Invalid Rows',
            p.invalidRows.toString(),
            color: p.invalidRows > 0 ? Colors.red[700] : null,
          ),
          const Divider(height: 20),
          Text(
            p.newQuestions > 0
                ? 'Ready to import ${p.newQuestions} question(s).'
                : 'Nothing to import.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: p.newQuestions > 0 ? Colors.green[700] : Colors.red[700],
            ),
          ),
          if (hasErrors) ...<Widget>[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: p.validationErrors
                      .take(10)
                      .map((String e) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(e,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.red)),
                          ))
                      .toList(),
                ),
              ),
            ),
            if (p.validationErrors.length > 10)
              Text(
                '… and ${p.validationErrors.length - 10} more error(s)',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _doImport() async {
    setState(() => _importing = true);
    await widget.onImportConfirmed();
    if (mounted) setState(() => _importing = false);
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CSV Export dialog ─────────────────────────────────────────────────────────

class _CsvExportDialog extends StatelessWidget {
  const _CsvExportDialog({required this.csvContent});
  final String csvContent;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Questions (CSV)'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  csvContent,
                  style: const TextStyle(
                      fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy All'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: csvContent));
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CSV copied to clipboard')),
            );
          },
        ),
      ],
    );
  }
}

// ── Result extension ──────────────────────────────────────────────────────────

extension _ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  String get failureMessage => (this as ResultFailure<T>).failure.message;
}
