import 'package:flutter/material.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';

/// Reusable primary button with loading state support.
///
/// Usage:
/// ```dart
/// AppButton(
///   label: context.l10n.login,
///   onPressed: _handleLogin,
///   isLoading: state.isSubmitting,
/// )
/// ```
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;
  final IconData? prefixIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.backgroundColor,
    this.textColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? AppDimensions.buttonHeight;
    final isEnabled = onPressed != null && !isLoading;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: AppDimensions.iconSm),
                const SizedBox(width: AppDimensions.spaceSm),
              ],
              Text(label, style: AppTextStyles.buttonLarge),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(onPressed: isEnabled ? onPressed : null, child: child)
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
            ),
            onPressed: isEnabled ? onPressed : null,
            child: child,
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: effectiveHeight,
      child: button,
    );
  }
}

/// Small text/icon button variant.
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: AppDimensions.iconSm) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}
