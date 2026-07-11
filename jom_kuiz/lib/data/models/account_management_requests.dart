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

  // PostgREST maps JSON body keys directly to PostgreSQL function parameter
  // names.  The create_child function uses the p_ prefix on every parameter,
  // so the JSON keys must match exactly.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'p_full_name': fullName,
        'p_username': username,
        'p_password': password,
        'p_education_level': educationLevel,
        'p_year_grade': yearGrade,
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

  // update_child function also uses p_ prefixed parameter names.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'p_full_name': fullName,
      'p_username': username,
      'p_education_level': educationLevel,
      'p_year_grade': yearGrade,
    };
    if (password != null) json['p_password'] = password;
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

  // reset_child_password function expects p_child_id and p_new_password.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'p_child_id': childId,
        'p_new_password': newPassword,
      };
}
