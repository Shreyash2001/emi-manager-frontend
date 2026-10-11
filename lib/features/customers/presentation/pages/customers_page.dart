import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_emi_manager/app/router/route_paths.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/extensions/num_extensions.dart';
import 'package:mobile_emi_manager/core/widgets/app_empty_view.dart';
import 'package:mobile_emi_manager/core/widgets/app_error_view.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';
import 'package:mobile_emi_manager/core/widgets/app_logo_widget.dart';
import 'package:mobile_emi_manager/features/customers/presentation/bloc/customer_bloc.dart';

/// Customers Directory Page designed according to screenshot specification.
class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerBloc>()..add(const LoadCustomers()),
      child: const _CustomersView(),
    );
  }
}

class _CustomersView extends StatefulWidget {
  const _CustomersView();

  @override
  State<_CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<_CustomersView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.addCustomer),
        backgroundColor: isDark ? AppColors.primary : const Color(0xFF111827),
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
        label: Text(
          'Add Customer',
          style: AppTextStyles.buttonMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state is CustomerLoading) {
                    return const AppLoader();
                  }
                  if (state is CustomerError) {
                    return AppErrorView(
                      message: state.failure.message,
                      onRetry: () =>
                          context.read<CustomerBloc>().add(const LoadCustomers()),
                    );
                  }
                  if (state is CustomerLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<CustomerBloc>()
                            .add(const RefreshCustomers());
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.pagePaddingHorizontal,
                          vertical: AppDimensions.spaceSm,
                        ),
                        children: [
                          // ─── Header: App Icon, Store Name, Location, Bell & Avatar ───
                          _buildTopHeader(context),
                          const SizedBox(height: AppDimensions.spaceMd),

                          // ─── Search Bar ─────────────────────────────────────────
                          _buildSearchBar(context),
                          const SizedBox(height: AppDimensions.spaceMd),

                          // ─── Filter Chips Row ────────────────────────────────────
                          _buildFilterChipsRow(context, state),
                          const SizedBox(height: AppDimensions.spaceSm),

                          // ─── Sort Bar ───────────────────────────────────────────
                          _buildSortBar(context, state),
                          const SizedBox(height: AppDimensions.spaceSm),

                          // ─── Customers Cards List ────────────────────────────────
                          if (state.customers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: AppEmptyView(
                                message: 'No matching customers found',
                                icon: Icons.people_outline,
                              ),
                            )
                          else
                            ...state.customers.map(
                              (customer) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppDimensions.spaceMd,
                                ),
                                child: _CustomerCard(customer: customer),
                              ),
                            ),
                          const SizedBox(height: 60), // Spacing for FAB
                        ],
                      ),
                    );
                  }
                  return const AppLoader();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top bar with App Icon, Store Name, Location, Notification Bell & Profile Avatar
  Widget _buildTopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        const AppLogoWidget(size: 38),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shree Ganesh Mobiles',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                      'Ganesh Nagar, Pune',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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

        // Notification Bell Icon with Red Badge Dot
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceXs),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Search Bar with Scanner Icon
  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context
              .read<CustomerBloc>()
              .add(SearchCustomers(query: value));
        },
        cursorColor: isDark ? Colors.white : AppColors.primary,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search by customer name, mobile or IMEI...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () {
              // Open barcode scanner
            },
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// Horizontal Filter Chips Row with dynamic counts
  Widget _buildFilterChipsRow(BuildContext context, CustomerLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = [
      {'label': 'All (${state.allCount})', 'value': 'All'},
      {'label': 'Active EMIs (${state.activeEmisCount})', 'value': 'Active EMIs'},
      {'label': 'Overdue (${state.overdueCount})', 'value': 'Overdue'},
      {'label': 'Due Today (${state.dueTodayCount})', 'value': 'Due Today'},
      {'label': 'On Track (${state.onTrackCount})', 'value': 'On Track'},
      {'label': 'Paid Off (${state.clearedCount})', 'value': 'Paid Off'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = state.activeFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF475569)),
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                context.read<CustomerBloc>().add(
                      FilterCustomers(category: f['value']!),
                    );
              },
              selectedColor: isDark ? AppColors.primary : const Color(0xFF1E293B),
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              elevation: 0,
              pressElevation: 0,
              side: BorderSide(
                color: isSelected
                    ? (isDark ? AppColors.primary : const Color(0xFF1E293B))
                    : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Sort Bar showing option selection dropdown and item counts
  Widget _buildSortBar(BuildContext context, CustomerLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PopupMenuButton<CustomerSortOption>(
          onSelected: (option) {
            context.read<CustomerBloc>().add(SortCustomers(sortOption: option));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          color: isDark ? AppColors.cardDark : Colors.white,
          itemBuilder: (context) => CustomerSortOption.values.map((opt) {
            final isSelected = opt == state.sortOption;
            return PopupMenuItem<CustomerSortOption>(
              value: opt,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isSelected
                        ? (isDark ? AppColors.primary : const Color(0xFF6C5CE7))
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: Color(0xFF6C5CE7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Sort by: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                Text(
                  state.sortOption.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF1E293B),
                ),
              ],
            ),
          ),
        ),
        Text(
          'Showing ${state.displayedCustomers.length} of ${state.allCount}',
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Rich Customer Card Widget
class _CustomerCard extends StatelessWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,##,##0.##', 'en_IN');

    // Accent line & Badge colors based on status
    Color borderAccentColor = Colors.transparent;
    Widget statusBadge;

    switch (customer.status) {
      case CustomerStatus.overdue:
        borderAccentColor = const Color(0xFFEF4444);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            '● ${customer.statusDetail}',
            style: const TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

      case CustomerStatus.dueToday:
        borderAccentColor = const Color(0xFF3B82F6);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: const Text(
            '● DUE TODAY',
            style: TextStyle(
              color: Color(0xFF1E40AF),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

      case CustomerStatus.onTrack:
        borderAccentColor = const Color(0xFF10B981);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF024B30),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: const Text(
            '● ON TRACK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

      case CustomerStatus.cleared:
        borderAccentColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            '✔ CLEARED / NOC ISSUED',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Line Bar
              Container(
                width: 4,
                color: borderAccentColor,
              ),

              // Card Interior Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Top Customer Info Row ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildAvatar(customer),
                              const SizedBox(width: AppDimensions.spaceSm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: AppTextStyles.headingMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_rounded,
                                        size: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer.mobileNumber,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : const Color(0xFF64748B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          statusBadge,
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceSm),

                      // ─── Device & IMEI Box ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceSm,
                          vertical: AppDimensions.spaceSm,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFF1F5F9),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardDark
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                Icons.smartphone_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.deviceName,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    customer.imei.startsWith('IMEI')
                                        ? customer.imei
                                        : 'IMEI: ${customer.imei}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : const Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Plan',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF64748B),
                                    fontSize: 10.5,
                                  ),
                                ),
                                Text(
                                  customer.status == CustomerStatus.cleared
                                      ? 'Completed'
                                      : 'EMI #${customer.currentEmiNumber} of ${customer.totalEmiMonths}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSm),

                      // ─── Financial Breakdown & Progress ─────────────────────
                      if (customer.status != CustomerStatus.cleared) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.installmentLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${currencyFormatter.format(customer.installmentAmount)}',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  customer.outstandingLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    color: customer.status ==
                                            CustomerStatus.overdue
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${currencyFormatter.format(customer.outstandingAmount)}',
                                  style: AppTextStyles.headingMedium.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: customer.status ==
                                            CustomerStatus.overdue
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (customer.totalEmiMonths > 0)
                                ? (customer.currentEmiNumber / customer.totalEmiMonths).clampedProgress
                                : 0.0,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: customer.status == CustomerStatus.overdue
                                ? const Color(0xFFDC2626)
                                : customer.status == CustomerStatus.dueToday
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF10B981),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${currencyFormatter.format(customer.paidAmount)} Paid',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${customer.currentEmiNumber} / ${customer.totalEmiMonths} Months',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'All 6 EMIs Cleared',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Outstanding',
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '₹0',
                                  style: AppTextStyles.headingMedium.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spaceSm),

                      // ─── Bottom Action Buttons ──────────────────────────────
                      _buildActionButtons(context, customer),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Customer customer) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF475569);

    if (customer.status == CustomerStatus.overdue) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
    } else if (customer.status == CustomerStatus.dueToday) {
      bg = const Color(0xFFDBEAFE);
      text = const Color(0xFF1E40AF);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          customer.initials,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Customer customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlinedTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final outlinedBorderColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    final primaryBtnBg = isDark ? AppColors.primary : const Color(0xFF111827);

    if (customer.status == CustomerStatus.overdue) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone_outlined, size: 15),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 38),
                foregroundColor: outlinedTextColor,
                side: BorderSide(color: outlinedBorderColor),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 38),
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.push('/customers/${customer.id}'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 38),
                backgroundColor: primaryBtnBg,
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Profile'),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (customer.status == CustomerStatus.dueToday) {
      return Row(
        children: [
          Expanded(
            flex: 6,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.payment_rounded, size: 16),
              label: const Text('Record Payment'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 38),
                backgroundColor: isDark ? const Color(0xFF6C5CE7) : const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: OutlinedButton(
              onPressed: () => context.push('/customers/${customer.id}'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 38),
                foregroundColor: outlinedTextColor,
                side: BorderSide(color: outlinedBorderColor),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Profile'),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 15),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (customer.status == CustomerStatus.onTrack) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.push('/customers/${customer.id}'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 38),
            backgroundColor: primaryBtnBg,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('View Profile'),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      );
    }

    // Cleared
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.push('/customers/${customer.id}'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 38),
          backgroundColor: primaryBtnBg,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('View Profile'),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
