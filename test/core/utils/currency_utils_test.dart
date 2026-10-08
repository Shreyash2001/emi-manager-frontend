import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_emi_manager/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils', () {
    group('format', () {
      test('formats zero correctly', () {
        final result = CurrencyUtils.format(0);
        expect(result.contains('₹'), isTrue);
        expect(result.contains('0'), isTrue);
      });

      test('formats positive amount with symbol', () {
        final result = CurrencyUtils.format(50000);
        expect(result.startsWith('₹'), isTrue);
        expect(result.contains('50'), isTrue);
      });

      test('formats decimal amount', () {
        final result = CurrencyUtils.format(1234.56);
        expect(result.contains('1,234'), isTrue);
        expect(result.contains('56'), isTrue);
      });
    });

    group('parse', () {
      test('parses valid number string', () {
        expect(CurrencyUtils.parse('1000.50'), equals(1000.50));
        expect(CurrencyUtils.parse('500'), equals(500.0));
      });

      test('returns null for non-numeric input', () {
        expect(CurrencyUtils.parse('abc'), isNull);
        expect(CurrencyUtils.parse(''), isNull);
      });
    });

    group('formatPercent', () {
      test('formats percentage correctly', () {
        expect(CurrencyUtils.formatPercent(12.5), equals('12.5%'));
        expect(CurrencyUtils.formatPercent(100), equals('100.0%'));
        expect(CurrencyUtils.formatPercent(0), equals('0.0%'));
      });
    });
  });
}
