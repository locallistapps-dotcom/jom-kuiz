import 'package:equatable/equatable.dart';

/// How the subject access was granted to the parent.
enum SubjectAccessSource {
  /// Granted as part of a subscription package.
  subscription,

  /// Manually granted by an admin.
  manual,

  /// Trial / promotional access.
  trial,
}

extension SubjectAccessSourceX on SubjectAccessSource {
  static SubjectAccessSource fromString(String value) {
    switch (value) {
      case 'manual':
        return SubjectAccessSource.manual;
      case 'trial':
        return SubjectAccessSource.trial;
      case 'subscription':
      default:
        return SubjectAccessSource.subscription;
    }
  }

  String get name {
    switch (this) {
      case SubjectAccessSource.subscription:
        return 'subscription';
      case SubjectAccessSource.manual:
        return 'manual';
      case SubjectAccessSource.trial:
        return 'trial';
    }
  }
}

/// A record that grants a parent (and all their linked children) access
/// to a specific subject.
///
/// Access is scoped to the parent — children inherit access automatically
/// because the service layer checks the parent's `parent_subject_access`
/// rows when validating a child's quiz attempt.
///
/// Uniqueness is enforced at the database level via
/// `UNIQUE(parent_id, subject_id)`.
class SubjectAccess extends Equatable {
  const SubjectAccess({
    required this.id,
    required this.parentId,
    required this.subjectId,
    required this.grantedAt,
    required this.source,
    this.expiresAt,
  });

  final String id;
  final String parentId;
  final String subjectId;
  final DateTime grantedAt;
  final SubjectAccessSource source;

  /// `null` means the access never expires.
  final DateTime? expiresAt;

  /// True when [expiresAt] is either null or in the future.
  bool get isValid =>
      expiresAt == null || expiresAt!.isAfter(DateTime.now());

  @override
  List<Object?> get props =>
      <Object?>[id, parentId, subjectId, grantedAt, source, expiresAt];
}
