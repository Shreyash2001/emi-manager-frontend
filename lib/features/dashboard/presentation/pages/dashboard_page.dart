import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_emi_manager/app/router/route_paths.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/widgets/app_error_view.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';
import 'package:mobile_emi_manager/core/widgets/app_logo_widget.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile_emi_manager/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile_emi_manager/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// ─── Currency Formatter (Indian number system: ₹1,84,500) ────────────────────
final _inrFmt = NumberFormat('#,##,##0.##', 'en_IN');
String _fmtCurrency(num value) => '₹${_inrFmt.format(value)}';

/// Dashboard page designed according to screenshot specification.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    final bloc = sl<DashboardBloc>();
    if (bloc.state is! DashboardLoaded && bloc.state is! DashboardLoading) {
      bloc.add(const LoadDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<DashboardBloc>(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const AppLoader();
            }
            if (state is DashboardError) {
              return AppErrorView(
                message: state.failure.message,
                onRetry: () =>
                    context.read<DashboardBloc>().add(const LoadDashboard()),
              );
            }
            if (state is DashboardLoaded) {
              return _DashboardContent(summary: state.summary);
            }
            return const AppLoader();
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;

  const _DashboardContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final ownerName = authState is AuthAuthenticated
        ? summary.ownerName
        : summary.ownerName;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(const RefreshDashboard());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePaddingHorizontal,
          vertical: AppDimensions.spaceSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: App Logo, Store Name, Location, Bell & Avatar ───────
            _buildTopHeader(context, summary),
            const SizedBox(height: AppDimensions.spaceLg),

            // ─── Greeting Title ───────────────────────────────────────────────
            _buildGreetingSection(context, ownerName),
            const SizedBox(height: AppDimensions.spaceLg),

            // ─── Metric Cards Row (Total Customers & Active EMIs) ─────────────
            _buildMetricsRow(context, summary),
            const SizedBox(height: AppDimensions.spaceMd),

            // ─── Total Collection Card (Full Width) ───────────────────────────
            _buildCollectionCard(context, summary),
            const SizedBox(height: AppDimensions.spaceLg),

            // ─── Quick Terminal Actions Section ───────────────────────────────
            _buildQuickActionsSection(context),
            const SizedBox(height: AppDimensions.space2xl),
          ],
        ),
      ),
    );
  }

  /// Top bar with App Icon, Store Name, Location, Notification dot & Profile Avatar
  Widget _buildTopHeader(BuildContext context, DashboardSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Row(
      children: [
        // App Logo Icon
        const AppLogoWidget(size: 38),
        const SizedBox(width: AppDimensions.spaceSm),

        // Store Name & Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.storeName,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      summary.storeLocation,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: AppDimensions.spaceSm),

        // Owner Profile Avatar
        GestureDetector(
          onTap: () => context.push(RoutePaths.profile),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const ClipOval(
              child: Icon(Icons.person, color: AppColors.primary, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  /// Greeting Section — wraps long owner names cleanly onto the next line
  Widget _buildGreetingSection(BuildContext context, String ownerName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NAMASTE STORE OWNER',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text.rich(
          TextSpan(
            text: 'Good morning, $ownerName! ',
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: textPrimary,
            ),
            children: const [
              TextSpan(text: '👋', style: TextStyle(fontSize: 22)),
            ],
          ),
          softWrap: true,
        ),
      ],
    );
  }

  /// Two Stat Cards Side by Side (Total Customers & Active EMIs)
  Widget _buildMetricsRow(BuildContext context, DashboardSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final cardBorder = isDark ? AppColors.borderDark : const Color(0xFFF1F5F9);
    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0xFF4B5563);
    final iconBg = isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9);
    final iconColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0xFF4B5563);

    return Row(
      children: [
        // Card 1: Total Customers
        Expanded(
          child: _buildMetricCard(
            context: context,
            title: 'Total Customers',
            cardBg: cardBg,
            cardBorder: cardBorder,
            labelColor: labelColor,
            topIcon: Icon(Icons.groups_outlined, size: 20, color: iconColor),
            topIconBg: iconBg,
            value: summary.totalCustomers.toString(),
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '+${summary.newCustomersThisMonth} this mo',
                style: TextStyle(
                  color: isDark
                      ? AppColors.primaryLight
                      : const Color(0xFF6C5CE7),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),

        // Card 2: Active EMIs
        Expanded(
          child: _buildMetricCard(
            context: context,
            title: 'Active EMIs',
            cardBg: cardBg,
            cardBorder: cardBorder,
            labelColor: labelColor,
            topIcon: Icon(
              Icons.smartphone_rounded,
              size: 19,
              color: isDark ? AppColors.primaryLight : const Color(0xFF6C5CE7),
            ),
            topIconBg: isDark
                ? AppColors.primary.withValues(alpha: 0.2)
                : const Color(0xFFEDE9FE),
            value: summary.activeEmis.toString(),
            subtext: Text(
              _fmtCurrency(summary.activeLoanAmount),
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF4B5563),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required Widget topIcon,
    required Color topIconBg,
    required String value,
    required Color cardBg,
    required Color cardBorder,
    required Color labelColor,
    Widget? badge,
    Widget? subtext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: labelColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: topIconBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Center(child: topIcon),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (badge != null) badge,
              if (subtext != null) subtext,
            ],
          ),
        ],
      ),
    );
  }

  /// Total Collection of this Month Card
  Widget _buildCollectionCard(BuildContext context, DashboardSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final cardBorder = isDark ? AppColors.borderDark : const Color(0xFFF1F5F9);
    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0xFF4B5563);
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Collection of this month',
                style: AppTextStyles.labelMedium.copyWith(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF024B30),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            _fmtCurrency(summary.totalCollection),
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Terminal Actions Card
  Widget _buildQuickActionsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final cardBorder = isDark ? AppColors.borderDark : const Color(0xFFF1F5F9);
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK TERMINAL ACTIONS',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
            color: labelColor,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceSm,
            vertical: AppDimensions.spaceMd,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: cardBorder),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // + Add Cust.
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: isDark
                        ? AppColors.primaryLight
                        : const Color(0xFF6C5CE7),
                    size: 22,
                  ),
                  bgColor: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : const Color(0xFFEDE9FE),
                  label: '+ Add Cust.',
                  textColor: textPrimary,
                  onTap: () async {
                    await context.push(RoutePaths.addCustomer);
                    if (context.mounted) {
                      context.read<DashboardBloc>().add(const LoadDashboard());
                    }
                  },
                ),
              ),

              // + Add Device
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icon(
                    Icons.phone_android_rounded,
                    color: isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0284C7),
                    size: 22,
                  ),
                  bgColor: isDark
                      ? const Color(0xFF0369A1).withValues(alpha: 0.25)
                      : const Color(0xFFE0F2FE),
                  label: '+ Add Device',
                  textColor: textPrimary,
                  onTap: () async {
                    await context.push(RoutePaths.addDevice);
                    if (context.mounted) {
                      context.read<DashboardBloc>().add(const LoadDashboard());
                    }
                  },
                ),
              ),

              // New EMI
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: const Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                  bgColor: const Color(0xFF4F46E5),
                  label: 'New EMI',
                  textColor: textPrimary,
                  onTap: () async {
                    await context.push(RoutePaths.addEmi);
                    if (context.mounted) {
                      context.read<DashboardBloc>().add(const LoadDashboard());
                    }
                  },
                ),
              ),

              // Record Pay
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                  bgColor: const Color(0xFF024B30),
                  label: 'Record Pay',
                  textColor: textPrimary,
                  onTap: () async {
                    await context.push(RoutePaths.recordPayment);
                    if (context.mounted) {
                      context.read<DashboardBloc>().add(const LoadDashboard());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required Widget icon,
    required Color bgColor,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(child: icon),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
