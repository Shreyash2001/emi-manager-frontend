import 'package:mobile_emi_manager/core/utils/currency_utils.dart';

/// Number extensions for formatting and common operations.
extension NumExtensions on num {
  /// Format as INR currency: ₹50,000.00
  String get inr => CurrencyUtils.format(this);

  /// Format as INR without decimals: ₹50,000
  String get inrNoDecimals => CurrencyUtils.formatNoDecimals(this);

  /// Format as compact INR: ₹50K
  String get inrCompact => CurrencyUtils.formatCompact(this);

  /// Format as percentage: 12.5%
  String get percent => CurrencyUtils.formatPercent(this);

  /// Clamp between 0 and 1 for progress indicators.
  double get clampedProgress {
    if (isNaN || isInfinite) return 0.0;
    return clamp(0.0, 1.0).toDouble();
  }

  /// Check if this is zero.
  bool get isZero => this == 0;

  /// Check if this is positive (> 0).
  bool get isPositive => this > 0;
}

extension IntExtensions on int {
  /// Ordinal suffix: 1st, 2nd, 3rd, 4th, etc.
  String get ordinal {
    if (this >= 11 && this <= 13) return '${this}th';
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}
