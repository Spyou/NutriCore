import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_check/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('returns error for empty email', () {
      expect(Validators.email(''), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.email('not-email'), isNotNull);
    });

    test('returns error for null email', () {
      expect(Validators.email(null), isNotNull);
    });
  });

  group('Validators.password', () {
    test('returns null for valid password', () {
      expect(Validators.password('123456'), isNull);
    });

    test('returns error for short password', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('returns error for empty password', () {
      expect(Validators.password(''), isNotNull);
    });
  });

  group('Validators.barcode', () {
    test('returns null for valid 13-digit barcode', () {
      expect(Validators.barcode('5901234123457'), isNull);
    });

    test('returns error for short barcode', () {
      expect(Validators.barcode('123'), isNotNull);
    });

    test('returns error for empty barcode', () {
      expect(Validators.barcode(''), isNotNull);
    });
  });

  group('Validators.weight', () {
    test('returns null for valid weight', () {
      expect(Validators.weight(70.0), isNull);
    });

    test('returns error for zero weight', () {
      expect(Validators.weight(0.0), isNotNull);
    });

    test('returns error for negative weight', () {
      expect(Validators.weight(-5.0), isNotNull);
    });

    test('returns error for null weight', () {
      expect(Validators.weight(null), isNotNull);
    });
  });

  group('Validators.age', () {
    test('returns null for valid age', () {
      expect(Validators.age(25), isNull);
    });

    test('returns error for zero age', () {
      expect(Validators.age(0), isNotNull);
    });

    test('returns error for null age', () {
      expect(Validators.age(null), isNotNull);
    });
  });
}
