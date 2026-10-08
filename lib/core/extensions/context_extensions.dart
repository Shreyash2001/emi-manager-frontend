import 'package:flutter/material.dart';
import 'package:mobile_emi_manager/app/localization/app_localizations.dart';

/// Convenience extensions on [BuildContext].
extension ContextExtensions on BuildContext {
  /// Access translations without verbose Localizations.of() calls.
  /// Usage: context.l10n.login
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Access the theme.
  ThemeData get theme => Theme.of(this);

  /// Access the color scheme.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Access the text theme.
  TextTheme get textStyles => Theme.of(this).textTheme;

  /// Screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Check if the device is a tablet (width >= 600).
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600;

  /// Bottom safe area padding.
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;

  /// Top safe area padding.
  double get topPadding => MediaQuery.paddingOf(this).top;

  /// Show a snackbar.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.primary,
      ),
    );
  }

  /// Hide the keyboard.
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
