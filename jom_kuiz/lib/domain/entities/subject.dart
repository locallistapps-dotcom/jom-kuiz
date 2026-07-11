import 'package:equatable/equatable.dart';

/// An academic subject (e.g. Mathematics, Science, English).
class Subject extends Equatable {
  const Subject({
    required this.subjectId,
    required this.name,
    required this.code,
    this.description,
    this.iconUrl,
  });

  final String subjectId;
  final String name;

  /// Short identifier, e.g. "MATH", "SCI".
  final String code;
  final String? description;
  final String? iconUrl;

  @override
  List<Object?> get props => <Object?>[subjectId, name, code, description, iconUrl];
}
