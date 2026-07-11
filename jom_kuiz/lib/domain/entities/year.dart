import 'package:equatable/equatable.dart';

/// An academic year / school grade level (e.g. Year 1 – Year 6).
class Year extends Equatable {
  const Year({
    required this.yearId,
    required this.name,
    required this.level,
    this.isActive = true,
  });

  final String yearId;

  /// Display name, e.g. "Year 1".
  final String name;

  /// Numeric level (1–6 for primary, etc.).
  final int level;

  /// Whether this year is currently offered.
  final bool isActive;

  @override
  List<Object?> get props => <Object?>[yearId, name, level, isActive];
}
