/// Request payloads for the Account Management REST/RPC endpoints.
///
/// Plain classes — no codegen required.

class CreateChildRequest {
  const CreateChildRequest({
    required this.fullName,
    required this.username,
    required this.password,
    required this.educationLevel,
    required this.yearGrade,
  });

  final String fullName;
  final String username;
  final String password;

  /// Snake-case value matching [EducationLevel.name] (e.g. `"primary"`).
  final String educationLevel;

  /// Display string (e.g. `"Year 3"`, `"Form 1"`, `"Preschool"`).
  final String yearGrade;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'username': username,
        'password': password,
        'education_level': educationLevel,
        'year_grade': yearGrade,
      };
}

class UpdateChildRequest {
  const UpdateChildRequest({
    required this.fullName,
    required this.username,
    required this.educationLevel,
    required this.yearGrade,
    this.password,
  });

  final String fullName;
  final String username;

  /// `null` means do not change the password.
  final String? password;
  final String educationLevel;
  final String yearGrade;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'full_name': fullName,
      'username': username,
      'education_level': educationLevel,
      'year_grade': yearGrade,
    };
    if (password != null) json['password'] = password;
    return json;
  }
}

class SetChildStatusRequest {
  const SetChildStatusRequest({required this.accountStatus});

  /// `"active"` or `"disabled"`.
  final String accountStatus;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'account_status': accountStatus};
}

class ResetChildPasswordRequest {
  const ResetChildPasswordRequest({
    required this.childId,
    required this.newPassword,
  });

  final String childId;
  final String newPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'child_id': childId,
        'new_password': newPassword,
      };
}
