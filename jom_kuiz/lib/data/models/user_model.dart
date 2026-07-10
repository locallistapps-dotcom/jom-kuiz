import '../../domain/entities/user.dart';

/// Wire format for a user account as returned by the Authentication API.
///
/// Hand-written `fromJson`/`toJson` (no `json_serializable` codegen) so this
/// source compiles standalone without requiring a `build_runner` step.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.emailVerifiedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final DateTime? emailVerifiedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      emailVerifiedAt: json['email_verified_at'] == null
          ? null
          : DateTime.parse(json['email_verified_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'full_name': fullName,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      emailVerifiedAt: emailVerifiedAt,
    );
  }
}
