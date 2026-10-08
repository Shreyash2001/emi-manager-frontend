import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/core/extensions/context_extensions.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_state.dart';

/// Profile page placeholder.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
            children: [
              const SizedBox(height: AppDimensions.spaceLg),
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              if (user != null) ...[
                Center(
                  child: Text(user.name, style: AppTextStyles.headingMedium),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Center(
                  child: Text(
                    user.mobileNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (user.storeName != null) ...[
                  const SizedBox(height: AppDimensions.spaceXs),
                  Center(
                    child: Text(
                      user.storeName!,
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppDimensions.spaceLg),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(context.l10n.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show language picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(context.l10n.theme),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show theme picker
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  context.l10n.logout,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  context.read<AuthBloc>().add(const LogoutRequested());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
