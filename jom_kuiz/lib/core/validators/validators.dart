/// Pure, stateless input validators shared across forms.
///
/// Each function returns `null` when the input is valid, or a
/// human-readable (English) error message otherwise. Screens are
/// responsible for localizing messages once `AppLocalizations` is wired in.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? minLength(String? value, int length, {String fieldName = 'This field'}) {
    if (value == null || value.trim().length < length) {
      return '$fieldName must be at least $length characters';
    }
    return null;
  }
}
