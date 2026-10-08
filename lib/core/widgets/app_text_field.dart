import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';

/// Reusable text field with consistent styling.
///
/// Usage:
/// ```dart
/// AppTextField(
///   label: context.l10n.mobileNumber,
///   hint: context.l10n.enterMobileNumber,
///   controller: _mobileController,
///   keyboardType: TextInputType.phone,
///   validator: ValidationUtils.mobileNumber,
/// )
/// ```
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? initialValue;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.initialValue,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.style,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveStyle = (widget.style ?? Theme.of(context).textTheme.bodyLarge)?.copyWith(
      color: isDark ? Colors.white : AppColors.textPrimary,
    ) ?? TextStyle(color: isDark ? Colors.white : AppColors.textPrimary);

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      style: effectiveStyle,
      cursorColor: isDark ? Colors.white : AppColors.primary,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: isDark ? const TextStyle(color: Colors.white70) : null,
        floatingLabelStyle: isDark ? const TextStyle(color: Colors.white) : null,
        hintText: widget.hint,
        hintStyle: isDark ? const TextStyle(color: AppColors.textSecondaryDark) : null,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  size: AppDimensions.iconMd,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : widget.suffixIcon,
        counterText: '',
      ),
    );
  }
}
