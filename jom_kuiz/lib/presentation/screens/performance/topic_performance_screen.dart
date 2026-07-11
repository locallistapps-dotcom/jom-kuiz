import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/performance_entities.dart';

/// Lists all topics the student has attempted, with per-topic stats
/// and a colour-coded recommendation chip.
///
/// Pushed from [PerformanceDashboardScreen].
class TopicPerformanceScreen extends StatefulWidget {
  const TopicPerformanceScreen({super.key, required this.topics});

  final List<TopicPerformance> topics;

  @override
  State<TopicPerformanceScreen> createState() =>
      _TopicPerformanceScreenState();
}

class _TopicPerformanceScreenState
    extends State<TopicPerformanceScreen> {
  String _search = '';
  String? _filterSubject;

  List<TopicPerformance> get _filtered {
    return widget.topics.where((TopicPerformance t) {
      final bool matchesSearch = _search.isEmpty ||
          t.topicName.toLowerCase().contains(_search.toLowerCase()) ||
          t.subjectName.toLowerCase().contains(_search.toLowerCase());
      final bool matchesSubject =
          _filterSubject == null || t.subjectId == _filterSubject;
      return matchesSearch && matchesSubject;
    }).toList();
  }

  List<String> get _subjects {
    final Map<String, String> seen = <String, String>{};
    for (final TopicPerformance t in widget.topics) {
      seen[t.subjectId] = t.subjectName;
    }
    return seen.values.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<TopicPerformance> displayed = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic Performance'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search topics…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: colors.surfaceContainerLow,
              ),
              onChanged: (String v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          // ── Subject filter chips ─────────────────────────────────────────
          if (_subjects.length > 1) ...<Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: <Widget>[
                  _FilterChip(
                    label: 'All',
                    selected: _filterSubject == null,
                    onTap: () =>
                        setState(() => _filterSubject = null),
                  ),
                  ..._subjects.map((String s) {
                    final String id = widget.topics
                        .firstWhere(
                            (TopicPerformance t) => t.subjectName == s)
                        .subjectId;
                    return _FilterChip(
                      label: s,
                      selected: _filterSubject == id,
                      onTap: () => setState(() => _filterSubject = id),
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Topic list ──────────────────────────────────────────────────
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Text('No topics match your search.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                colors.onSurface.withValues(alpha: 0.55))))
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext ctx, int i) =>
                        _TopicCard(topic: displayed[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Topic card ────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  const _TopicCard({super.key, required this.topic});
  final TopicPerformance topic;

  Color _recommendationColor(BuildContext context) {
    final ColorScheme c = Theme.of(context).colorScheme;
    if (topic.averageScore >= 85) return Colors.green.shade700;
    if (topic.averageScore >= 70) return Colors.blue.shade700;
    if (topic.averageScore >= 50) return Colors.orange.shade700;
    return c.error;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color recColor = _recommendationColor(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Row 1: topic name + recommendation chip
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  topic.topicName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: recColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: recColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  topic.recommendation,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: recColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${topic.subjectName} › ${topic.chapterName} › ${topic.yearName}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: topic.averageScore / 100,
              minHeight: 7,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation<Color>(recColor),
            ),
          ),
          const SizedBox(height: 8),

          // Row 2: stats
          Row(
            children: <Widget>[
              _StatPill(
                  label: 'Avg',
                  value:
                      '${topic.averageScore.toStringAsFixed(1)} %',
                  color: recColor),
              const SizedBox(width: 8),
              _StatPill(
                  label: 'Best',
                  value:
                      '${topic.bestScore.toStringAsFixed(1)} %',
                  color: Colors.green.shade700),
              const SizedBox(width: 8),
              _StatPill(
                  label: 'Attempts',
                  value: topic.attempts.toString(),
                  color: colors.primary),
              const Spacer(),
              if (topic.lastAttempt != null)
                Text(
                  DateFormat('d MMM y').format(topic.lastAttempt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          colors.onSurface.withValues(alpha: 0.45)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(
      {super.key,
      required this.label,
      required this.value,
      required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 9)),
          Text(value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurface,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
