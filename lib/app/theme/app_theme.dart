import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';

/// Centralized theme configuration.
///
/// Supports:
///   - Light theme
///   - Dark theme
///   - Dynamic store-specific theme colors (safely parsed from backend)
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(brightness: Brightness.light);
  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.textInverse,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.textInverse,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textInverse,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
      onSecondaryContainer: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textInverse,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: isDark ? AppColors.cardDark : AppColors.card,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceDark
            : AppColors.border.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: AppDimensions.spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.inputBorderWidth,
          ),
        ),
        labelStyle: AppTextStyles.labelLarge.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        floatingLabelStyle: AppTextStyles.labelLarge.copyWith(
          color: isDark ? Colors.white : AppColors.primary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textDisabled,
        ),
        prefixStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        suffixStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),

      // Text Selection & Cursor
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: isDark ? Colors.white : AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.4),
        selectionHandleColor: isDark ? Colors.white : AppColors.primary,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTextStyles.buttonLarge,
          elevation: 0,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTextStyles.buttonLarge,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme.copyWith(
              displayLarge: isDark
                  ? AppTextStyles.displayLarge.copyWith(color: Colors.white)
                  : AppTextStyles.displayLarge,
              displayMedium: isDark
                  ? AppTextStyles.displayMedium.copyWith(color: Colors.white)
                  : AppTextStyles.displayMedium,
              headlineLarge: isDark
                  ? AppTextStyles.headingLarge.copyWith(color: Colors.white)
                  : AppTextStyles.headingLarge,
              headlineMedium: isDark
                  ? AppTextStyles.headingMedium.copyWith(color: Colors.white)
                  : AppTextStyles.headingMedium,
              headlineSmall: isDark
                  ? AppTextStyles.headingSmall.copyWith(color: Colors.white)
                  : AppTextStyles.headingSmall,
              bodyLarge: isDark
                  ? AppTextStyles.bodyLarge.copyWith(color: Colors.white)
                  : AppTextStyles.bodyLarge,
              bodyMedium: isDark
                  ? AppTextStyles.bodyMedium.copyWith(color: Colors.white)
                  : AppTextStyles.bodyMedium,
              bodySmall: isDark
                  ? AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)
                  : AppTextStyles.bodySmall,
              labelLarge: isDark
                  ? AppTextStyles.labelLarge.copyWith(color: Colors.white)
                  : AppTextStyles.labelLarge,
              labelMedium: isDark
                  ? AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondaryDark)
                  : AppTextStyles.labelMedium,
            ),
      ).apply(
        bodyColor: isDark ? Colors.white : AppColors.textPrimary,
        displayColor: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  /// Safely parse a store-specific theme color from a hex string.
  /// Returns [fallback] if parsing fails, preventing a bad server value
  /// from crashing the app.
  static Color safeParseColor(String? hexColor, {Color? fallback}) {
    if (hexColor == null || hexColor.isEmpty) {
      return fallback ?? AppColors.primary;
    }
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return fallback ?? AppColors.primary;
    } catch (_) {
      return fallback ?? AppColors.primary;
    }
  }

  /// Build a theme customized with store-specific colors returned by the backend.
  /// All values are safely validated before being applied.
  static ThemeData storeTheme({
    required ThemeData base,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? accentColorHex,
  }) {
    final primary = safeParseColor(primaryColorHex, fallback: AppColors.primary);
    final secondary = safeParseColor(
      secondaryColorHex,
      fallback: AppColors.secondary,
    );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
      ),
    );
  }
}
