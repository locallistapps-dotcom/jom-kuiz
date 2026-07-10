import 'package:flutter_test/flutter_test.dart';
import 'package:jom_kuiz/core/validators/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects malformed input', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a valid address', () {
      expect(Validators.email('parent@jomkuiz.my'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short passwords', () {
      expect(Validators.password('123'), isNotNull);
    });

    test('accepts passwords meeting the minimum length', () {
      expect(Validators.password('goodpassword'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatched passwords', () {
      expect(Validators.confirmPassword('abc', 'xyz'), isNotNull);
    });

    test('accepts matching passwords', () {
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });
  });
}
