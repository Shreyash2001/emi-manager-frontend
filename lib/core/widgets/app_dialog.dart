import 'package:flutter/material.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/core/widgets/app_button.dart';

/// Reusable dialog utility.
class AppDialog {
  AppDialog._();

  /// Show a confirmation dialog.
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Text(title, style: AppTextStyles.headingMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? 'Cancel'),
          ),
          AppButton(
            label: confirmLabel ?? 'Confirm',
            onPressed: () => Navigator.of(context).pop(true),
            isFullWidth: false,
            backgroundColor:
                isDangerous ? Colors.red : null,
          ),
        ],
      ),
    );
  }

  /// Show an info/message dialog.
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String? okLabel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Text(title, style: AppTextStyles.headingMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          AppButton(
            label: okLabel ?? 'OK',
            onPressed: () => Navigator.of(context).pop(),
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  /// Show an error dialog.
  static Future<void> showError(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    return showInfo(
      context,
      title: title ?? 'Error',
      message: message,
    );
  }
}
