import 'package:flutter/material.dart';

import '../../../domain/entities/performance_entities.dart';

/// Lists all chapters within a subject, showing average score and
/// "Weak" / "Strong" badges.
///
/// Pushed from [SubjectPerformanceScreen] with pre-filtered chapters.
class ChapterPerformanceScreen extends StatelessWidget {
  const ChapterPerformanceScreen({
    super.key,
    required this.subjectName,
    required this.chapters,
  });

  final String subjectName;
  final List<ChapterPerformance> chapters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<ChapterPerformance> strong =
        chapters.where((ChapterPerformance c) => c.isStrong).toList();
    final List<ChapterPerformance> weak =
        chapters.where((ChapterPerformance c) => c.isWeak).toList();
    final List<ChapterPerformance> average = chapters
        .where((ChapterPerformance c) => !c.isStrong && !c.isWeak)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: chapters.isEmpty
          ? Center(
              child: Text(
                'No chapter data available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                // ── Summary chips ──────────────────────────────────────────
                if (strong.isNotEmpty || weak.isNotEmpty) ...<Widget>[
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      if (strong.isNotEmpty)
                        _SummaryChip(
                          label:
                              '${strong.length} Strong Chapter${strong.length != 1 ? 's' : ''}',
                          color: Colors.green.shade700,
                          icon: Icons.trending_up,
                        ),
                      if (weak.isNotEmpty)
                        _SummaryChip(
                          label:
                              '${weak.length} Weak Chapter${weak.length != 1 ? 's' : ''}',
                          color: Theme.of(context).colorScheme.error,
                          icon: Icons.warning_amber_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Weak chapters section ──────────────────────────────────
                if (weak.isNotEmpty) ...<Widget>[
                  _SectionLabel(label: 'NEEDS WORK', color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 8),
                  ...weak.map((ChapterPerformance c) => _ChapterTile(chapter: c)),
                  const SizedBox(height: 16),
                ],

                // ── Average chapters section ───────────────────────────────
                if (average.isNotEmpty) ...<Widget>[
                  const _SectionLabel(label: 'IN PROGRESS'),
                  const SizedBox(height: 8),
                  ...average.map((ChapterPerformance c) => _ChapterTile(chapter: c)),
                  const SizedBox(height: 16),
                ],

                // ── Strong chapters section ────────────────────────────────
                if (strong.isNotEmpty) ...<Widget>[
                  _SectionLabel(label: 'STRONG', color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  ...strong.map((ChapterPerformance c) => _ChapterTile(chapter: c)),
                ],
              ],
            ),
    );
  }
}

// ── Chapter tile ──────────────────────────────────────────────────────────────

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({super.key, required this.chapter});
  final ChapterPerformance chapter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color scoreColor = chapter.isStrong
        ? Colors.green.shade700
        : chapter.isWeak
            ? colors.error
            : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  chapter.chapterName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (chapter.isStrong)
                _InlineBadge(label: 'STRONG', color: Colors.green.shade700)
              else if (chapter.isWeak)
                _InlineBadge(label: 'WEAK', color: colors.error),
              const SizedBox(width: 8),
              Text(
                '${chapter.averageScore.toStringAsFixed(1)} %',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: scoreColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: chapter.averageScore / 100,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${chapter.totalQuizzes} quiz${chapter.totalQuizzes != 1 ? 'zes' : ''}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({super.key, required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color ??
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {super.key,
      required this.label,
      required this.color,
      required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 14, color: color),
        label: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 10),
        ),
      );
}
