/// Request payloads for the Authentication REST endpoints.
///
/// Kept as plain classes (not `Freezed`) so this compiles without codegen.

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'password': password,
      };
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'email': email,
        'password': password,
      };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{'email': email};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.resetToken,
    required this.newPassword,
  });

  final String resetToken;
  final String newPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reset_token': resetToken,
        'new_password': newPassword,
      };
}

class RefreshRequest {
  const RefreshRequest({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => <String, dynamic>{'refresh_token': refreshToken};
}
