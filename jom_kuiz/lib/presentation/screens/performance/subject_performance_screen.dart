import 'package:flutter/material.dart';

import '../../../domain/entities/performance_entities.dart';
import 'chapter_performance_screen.dart';

/// Lists all subjects with their average score and progress bar.
///
/// Tapping a subject navigates to [ChapterPerformanceScreen] showing
/// that subject's chapters.
class SubjectPerformanceScreen extends StatelessWidget {
  const SubjectPerformanceScreen({super.key, required this.subjects});

  final List<SubjectPerformance> subjects;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subject Performance')),
      body: subjects.isEmpty
          ? Center(
              child: Text(
                'No subject data available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext ctx, int i) =>
                  _SubjectCard(subject: subjects[i]),
            ),
    );
  }
}

// ── Subject card ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({super.key, required this.subject});
  final SubjectPerformance subject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color scoreColor = subject.isStrong
        ? Colors.green.shade700
        : subject.isWeak
            ? colors.error
            : Colors.orange.shade700;

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChapterPerformanceScreen(
          subjectName: subject.subjectName,
          chapters: subject.chapters,
        ),
      )),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header row
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    subject.subjectName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (subject.isStrong)
                  _Badge(label: 'STRONG', color: Colors.green.shade700)
                else if (subject.isWeak)
                  _Badge(label: 'WEAK', color: colors.error),
                const SizedBox(width: 8),
                Text(
                  '${subject.averageScore.toStringAsFixed(1)} %',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: scoreColor),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: subject.averageScore / 100,
                minHeight: 8,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(height: 8),

            // Footer stats
            Row(
              children: <Widget>[
                Icon(Icons.quiz_outlined, size: 14, color: colors.outline),
                const SizedBox(width: 4),
                Text(
                  '${subject.totalQuizzes} quiz${subject.totalQuizzes != 1 ? 'zes' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.55)),
                ),
                const Spacer(),
                Text(
                  '${subject.chapters.length} chapter${subject.chapters.length != 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.55)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: colors.outline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      );
}
