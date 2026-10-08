import 'package:flutter/material.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/core/widgets/app_button.dart';

/// Reusable error view for feature screens.
///
/// Usage:
/// ```dart
/// AppErrorView(
///   message: context.l10n.networkError,
///   onRetry: () => bloc.add(LoadCustomers()),
/// )
/// ```
class AppErrorView extends StatelessWidget {
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              message ?? 'An error occurred',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceLg),
              AppButton(
                label: retryLabel ?? 'Retry',
                onPressed: onRetry,
                isFullWidth: false,
                prefixIcon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
