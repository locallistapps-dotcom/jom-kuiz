import 'package:intl/intl.dart';

/// Shared date/time formatting helpers so screens don't hand-roll `DateFormat`
/// patterns inconsistently.
abstract final class DateFormatter {
  static String short(DateTime date) => DateFormat.yMMMd().format(date);

  static String withTime(DateTime date) => DateFormat.yMMMd().add_jm().format(date);

  static String relative(DateTime date, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration diff = reference.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return short(date);
  }
}
