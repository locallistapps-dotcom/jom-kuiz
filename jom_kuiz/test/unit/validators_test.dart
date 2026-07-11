import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/validators/validators.dart';

void main() {
  // ---------------------------------------------------------------------------
  // required
  // ---------------------------------------------------------------------------
  group('Validators.required', () {
    test('returns null when value has non-whitespace content', () {
      expect(Validators.required('hello'), isNull);
    });

    test('returns error for null', () {
      expect(Validators.required(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.required(''), isNotNull);
    });

    test('returns error for whitespace-only string', () {
      expect(Validators.required('   '), isNotNull);
    });

    test('uses custom fieldName in message', () {
      final String? msg = Validators.required('', fieldName: 'Phone');
      expect(msg, contains('Phone'));
    });
  });

  // ---------------------------------------------------------------------------
  // email
  // ---------------------------------------------------------------------------
  group('Validators.email', () {
    test('accepts a valid email', () {
      expect(Validators.email('parent@example.com'), isNull);
    });

    test('rejects missing @ symbol', () {
      expect(Validators.email('notanemail'), isNotNull);
    });

    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects null input', () {
      expect(Validators.email(null), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // password
  // ---------------------------------------------------------------------------
  group('Validators.password', () {
    test('accepts a password at the minimum length', () {
      expect(Validators.password('abcdefgh'), isNull); // exactly 8 chars
    });

    test('accepts a longer password', () {
      expect(Validators.password('supersecretpass123!'), isNull);
    });

    test('rejects a password shorter than the minimum', () {
      expect(Validators.password('short'), isNotNull);
    });

    test('rejects null', () {
      expect(Validators.password(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(Validators.password(''), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // confirmPassword
  // ---------------------------------------------------------------------------
  group('Validators.confirmPassword', () {
    test('returns null when both values match', () {
      expect(Validators.confirmPassword('myPass1!', 'myPass1!'), isNull);
    });

    test('returns error when values differ', () {
      expect(Validators.confirmPassword('myPass1!', 'different'), isNotNull);
    });

    test('returns error when confirm is empty', () {
      expect(Validators.confirmPassword('', 'myPass1!'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // minLength
  // ---------------------------------------------------------------------------
  group('Validators.minLength', () {
    test('returns null when value meets the minimum', () {
      expect(Validators.minLength('ab', 2), isNull);
    });

    test('returns null when value exceeds the minimum', () {
      expect(Validators.minLength('abcde', 2), isNull);
    });

    test('returns error when value is below the minimum', () {
      expect(Validators.minLength('a', 2), isNotNull);
    });

    test('error message contains the custom fieldName', () {
      final String? msg = Validators.minLength('a', 2, fieldName: 'Full name');
      expect(msg, contains('Full name'));
      expect(msg, contains('2'));
    });

    test('returns error for null input', () {
      expect(Validators.minLength(null, 2), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // phone  (optional field — blank is valid, non-blank must match E.164-ish)
  // ---------------------------------------------------------------------------
  group('Validators.phone', () {
    test('returns null for an empty string (phone is optional)', () {
      expect(Validators.phone(''), isNull);
    });

    test('returns null for null (phone is optional)', () {
      expect(Validators.phone(null), isNull);
    });

    test('returns null for a whitespace-only string (treated as absent)', () {
      expect(Validators.phone('   '), isNull);
    });

    test('accepts a 10-digit local number', () {
      expect(Validators.phone('0123456789'), isNull);
    });

    test('accepts a number with a leading + (E.164 style)', () {
      expect(Validators.phone('+60123456789'), isNull);
    });

    test('accepts a number at the minimum length of 8 digits', () {
      expect(Validators.phone('12345678'), isNull);
    });

    test('accepts a number at the maximum length of 15 digits', () {
      expect(Validators.phone('123456789012345'), isNull);
    });

    test('rejects a number with fewer than 8 digits', () {
      expect(Validators.phone('1234567'), isNotNull); // 7 digits
    });

    test('rejects a number with more than 15 digits', () {
      expect(Validators.phone('1234567890123456'), isNotNull); // 16 digits
    });

    test('rejects a string containing letters', () {
      expect(Validators.phone('abc1234567'), isNotNull);
    });

    test('rejects a number with spaces inside it', () {
      expect(Validators.phone('012 345 6789'), isNotNull);
    });

    test('rejects a number with hyphens', () {
      expect(Validators.phone('012-345-6789'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // maxLength
  // ---------------------------------------------------------------------------
  group('Validators.maxLength', () {
    test('returns null when value is within the limit', () {
      expect(Validators.maxLength('hello', 10), isNull);
    });

    test('returns null when value equals the limit exactly', () {
      expect(Validators.maxLength('hello', 5), isNull);
    });

    test('returns null for an empty string', () {
      expect(Validators.maxLength('', 5), isNull);
    });

    test('returns null for null', () {
      expect(Validators.maxLength(null, 5), isNull);
    });

    test('returns an error when value exceeds the limit', () {
      expect(Validators.maxLength('toolong', 5), isNotNull);
    });

    test('error message contains the custom fieldName and limit', () {
      final String? msg = Validators.maxLength('x' * 300, 280, fieldName: 'Bio');
      expect(msg, contains('Bio'));
      expect(msg, contains('280'));
    });
  });

  // ---------------------------------------------------------------------------
  // requireTrue
  // ---------------------------------------------------------------------------
  group('Validators.requireTrue', () {
    test('returns null when value is true', () {
      expect(Validators.requireTrue(true), isNull);
    });

    test('returns error when value is false', () {
      expect(Validators.requireTrue(false), isNotNull);
    });

    test('uses the custom message', () {
      expect(Validators.requireTrue(false, message: 'Must agree'), 'Must agree');
    });
  });
}
