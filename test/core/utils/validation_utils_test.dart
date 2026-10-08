import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_emi_manager/core/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    group('mobileNumber', () {
      test('accepts valid 10-digit number starting with 6-9 or dummy 1234567890', () {
        expect(ValidationUtils.mobileNumber('9876543210'), isNull);
        expect(ValidationUtils.mobileNumber('6123456789'), isNull);
        expect(ValidationUtils.mobileNumber('7000000000'), isNull);
        expect(ValidationUtils.mobileNumber('8999999999'), isNull);
        expect(ValidationUtils.mobileNumber('1234567890'), isNull);
      });

      test('rejects number starting with 0-5 (except dummy number)', () {
        expect(ValidationUtils.mobileNumber('2234567890'), isNotNull);
        expect(ValidationUtils.mobileNumber('5000000000'), isNotNull);
      });

      test('rejects numbers less than 10 digits', () {
        expect(ValidationUtils.mobileNumber('987654321'), isNotNull);
        expect(ValidationUtils.mobileNumber('123'), isNotNull);
      });

      test('rejects numbers more than 10 digits', () {
        expect(ValidationUtils.mobileNumber('98765432101'), isNotNull);
      });

      test('rejects empty or null', () {
        expect(ValidationUtils.mobileNumber(''), isNotNull);
        expect(ValidationUtils.mobileNumber(null), isNotNull);
      });
    });

    group('password', () {
      test('accepts password with 6+ characters or dummy 12345', () {
        expect(ValidationUtils.password('password123'), isNull);
        expect(ValidationUtils.password('abc123'), isNull);
        expect(ValidationUtils.password('12345'), isNull);
      });

      test('rejects password with fewer than 6 characters (except dummy password)', () {
        expect(ValidationUtils.password('abc'), isNotNull);
        expect(ValidationUtils.password('1234'), isNotNull);
      });

      test('rejects empty or null', () {
        expect(ValidationUtils.password(''), isNotNull);
        expect(ValidationUtils.password(null), isNotNull);
      });
    });

    group('email', () {
      test('accepts valid email', () {
        expect(ValidationUtils.email('user@example.com'), isNull);
        expect(ValidationUtils.email('test.user+tag@domain.co.in'), isNull);
      });

      test('rejects invalid email', () {
        expect(ValidationUtils.email('not-an-email'), isNotNull);
        expect(ValidationUtils.email('missing@dot'), isNotNull);
        expect(ValidationUtils.email('@nodomain.com'), isNotNull);
      });

      test('rejects empty or null', () {
        expect(ValidationUtils.email(''), isNotNull);
        expect(ValidationUtils.email(null), isNotNull);
      });
    });

    group('amount', () {
      test('accepts valid positive amount', () {
        expect(ValidationUtils.amount('1000.00'), isNull);
        expect(ValidationUtils.amount('0.01'), isNull);
        expect(ValidationUtils.amount('50000'), isNull);
      });

      test('rejects non-numeric input', () {
        expect(ValidationUtils.amount('abc'), isNotNull);
        expect(ValidationUtils.amount(''), isNotNull);
      });

      test('rejects zero or negative', () {
        expect(ValidationUtils.amount('0'), isNotNull);
        expect(ValidationUtils.amount('-100'), isNotNull);
      });
    });

    group('required', () {
      test('accepts non-empty value', () {
        expect(ValidationUtils.required('hello'), isNull);
        expect(ValidationUtils.required('  a  '), isNull);
      });

      test('rejects empty or whitespace-only', () {
        expect(ValidationUtils.required(''), isNotNull);
        expect(ValidationUtils.required('   '), isNotNull);
        expect(ValidationUtils.required(null), isNotNull);
      });
    });
  });
}
