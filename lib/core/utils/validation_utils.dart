import 'package:mobile_emi_manager/core/constants/app_constants.dart';

/// Centralized form validation utilities.
/// Reuse these in every form — never duplicate validation logic.
class ValidationUtils {
  ValidationUtils._();

  /// Validate required field. Returns error message or null.
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }
    return null;
  }

  /// Validate 10-digit Indian mobile number.
  static String? mobileNumber(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length != AppConstants.mobileNumberLength) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Please enter a valid Indian mobile number';
    }
    return null;
  }

  /// Validate password (minimum 6 characters).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  /// Validate email address.
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate monetary amount.
  static String? amount(String? value, {num? min, num? max}) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null) return 'Please enter a valid amount';
    if (parsed < (min ?? AppConstants.minAmount)) {
      return 'Amount must be at least ${min ?? AppConstants.minAmount}';
    }
    if (max != null && parsed > max) {
      return 'Amount must not exceed $max';
    }
    return null;
  }

  /// Validate a date string is not empty.
  static String? date(String? value) {
    if (value == null || value.isEmpty) return 'Date is required';
    return null;
  }

  /// Validate minimum length.
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      return '${fieldName ?? 'Field'} must be at least $min characters';
    }
    return null;
  }

  /// Validate maximum length.
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'Field'} must not exceed $max characters';
    }
    return null;
  }

  /// Combine multiple validators. Returns the first error found.
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
