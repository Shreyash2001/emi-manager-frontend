/// String extensions for common operations.
extension StringExtensions on String {
  /// Capitalize the first letter.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// Convert snake_case or UPPER_CASE to Title Case.
  String get toTitleCase => split(RegExp(r'[_\s]'))
      .map((word) => word.capitalized)
      .join(' ');

  /// Truncate to [maxLength] characters with ellipsis.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}...';

  /// Check if the string is a valid Indian mobile number.
  bool get isValidMobileNumber =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(this);

  /// Check if the string is a valid email.
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  /// Remove all whitespace.
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Return null if empty, otherwise return self.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Check if the string represents a valid number.
  bool get isNumeric => double.tryParse(this) != null;
}

/// Nullable String extensions.
extension NullableStringExtensions on String? {
  /// Return [fallback] if null or empty.
  String orDefault([String fallback = '—']) =>
      (this == null || this!.isEmpty) ? fallback : this!;

  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
