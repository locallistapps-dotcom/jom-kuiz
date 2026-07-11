/// Error codes for the Topic module.
///
/// Format: TOPIC-NNN
abstract final class TopicErrorCodes {
  /// No topic found for the given ID.
  static const String topicNotFound = 'TOPIC-001';

  /// A topic with the same name already exists in this chapter.
  static const String duplicateTopicName = 'TOPIC-002';

  /// The submitted topic data failed validation.
  static const String invalidTopicData = 'TOPIC-003';

  /// The topic could not be deleted (e.g. it has dependent questions).
  static const String topicDeleteFailed = 'TOPIC-004';

  /// Generic server-side failure for any topic operation.
  static const String topicOperationFailed = 'TOPIC-005';
}
