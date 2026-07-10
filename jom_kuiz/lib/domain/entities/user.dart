import 'package:equatable/equatable.dart';

/// Core domain representation of an authenticated account.
///
/// Deliberately minimal for the Authentication module -- profile fields
/// beyond identity (avatar, role-specific data) belong to the Parent/Child
/// modules once those are implemented.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.emailVerifiedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final DateTime? emailVerifiedAt;

  bool get isEmailVerified => emailVerifiedAt != null;

  @override
  List<Object?> get props => <Object?>[id, email, fullName, emailVerifiedAt];
}
