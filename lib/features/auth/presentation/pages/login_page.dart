import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/core/extensions/context_extensions.dart';
import 'package:mobile_emi_manager/core/utils/validation_utils.dart';
import 'package:mobile_emi_manager/core/widgets/app_button.dart';
import 'package:mobile_emi_manager/core/widgets/app_text_field.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_state.dart';

/// Login page — structurally connected to AuthBloc.
///
/// Flow:
///   LoginPage → AuthBloc → LoginUseCase → AuthRepository → AuthRemoteDataSource → ApiClient → Backend
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(state.failure.message, isError: true);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.space3xl),
                  _buildHeader(context),
                  const SizedBox(height: AppDimensions.space2xl),
                  _LoginForm(isLoading: state is AuthLoading),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(
            Icons.store_rounded,
            color: Colors.white,
            size: AppDimensions.iconLg,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          context.l10n.appName,
          style: AppTextStyles.displayMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          context.l10n.login,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatefulWidget {
  final bool isLoading;

  const _LoginForm({required this.isLoading});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.hideKeyboard();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              mobileNumber: _mobileController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: context.l10n.mobileNumber,
            hint: context.l10n.enterMobileNumber,
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.phone_android),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: ValidationUtils.mobileNumber,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            label: context.l10n.password,
            hint: context.l10n.enterPassword,
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.lock_outline),
            onSubmitted: (_) => _submit(),
            validator: ValidationUtils.password,
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppButton(
            label: context.l10n.login,
            onPressed: _submit,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
        ],
      ),
    );
  }
}
