import 'package:intl/intl.dart';
import 'package:mobile_emi_manager/core/constants/app_constants.dart';

/// Centralized currency formatting utilities.
/// Always use these — never format currency inline in widgets.
class CurrencyUtils {
  CurrencyUtils._();

  static final _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static final _inrFormatterNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 1,
  );

  /// Full INR format: ₹50,000.00
  static String format(num amount) {
    return _inrFormatter.format(amount);
  }

  /// INR format without decimals: ₹50,000
  static String formatNoDecimals(num amount) {
    return _inrFormatterNoDecimals.format(amount);
  }

  /// Compact format for large numbers: ₹50K, ₹1.2L
  static String formatCompact(num amount) {
    return _compactFormatter.format(amount);
  }

  /// Parse a currency string back to double.
  static double? parse(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Format just the number with Indian grouping (no symbol).
  static String formatNumber(num amount) {
    return NumberFormat('#,##,##0.##', 'en_IN').format(amount);
  }

  /// Percentage format: 12.5%
  static String formatPercent(num percent) {
    return '${percent.toStringAsFixed(1)}%';
  }
}
