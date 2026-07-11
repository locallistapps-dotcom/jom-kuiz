import 'package:equatable/equatable.dart';

/// A topic within a chapter.
class Topic extends Equatable {
  const Topic({
    required this.topicId,
    required this.chapterId,
    required this.name,
    required this.order,
    this.description,
  });

  final String topicId;
  final String chapterId;
  final String name;

  /// Display order within the chapter.
  final int order;
  final String? description;

  @override
  List<Object?> get props => <Object?>[topicId, chapterId, name, order, description];
}
