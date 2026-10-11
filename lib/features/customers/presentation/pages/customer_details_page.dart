import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_emi_manager/app/router/route_paths.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/widgets/app_empty_view.dart';
import 'package:mobile_emi_manager/core/widgets/app_error_view.dart';
import 'package:mobile_emi_manager/core/widgets/app_loader.dart';
import 'package:mobile_emi_manager/features/customers/domain/repositories/customer_repository.dart';
import 'package:mobile_emi_manager/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Local palette ───────────────────────────────────────────────────────────
const _kPurple = Color(0xFF6C5CE7);
const _kPurpleLight = Color(0xFFEDE9FE);
const _kGreen = Color(0xFF00B894);
const _kGreenLight = Color(0xFFE6FAF6);
const _kAmber = Color(0xFFF59E0B);
const _kAmberLight = Color(0xFFFFF8E1);
const _kRed = Color(0xFFE17055);
const _kRedLight = Color(0xFFFEF2F2);
const _kBlueDark = Color(0xFF1E293B);
const _kGrey = Color(0xFF64748B);
const _kGreyLight = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);
const _kCardBg = Color(0xFFFFFFFF);

// ─── EMI Payment status enum ─────────────────────────────────────────────────
enum _PayStatus { paid, pending, overdue, settled }

// ─── Models ──────────────────────────────────────────────────────────────────
class _PayRecord {
  final String label;
  final String method;
  final String date;
  final String ref;
  final double amount;
  final _PayStatus status;

  const _PayRecord({
    required this.label,
    required this.method,
    required this.date,
    required this.ref,
    required this.amount,
    required this.status,
  });

  factory _PayRecord.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'paid').toLowerCase();
    _PayStatus payStatus = _PayStatus.paid;
    if (statusStr == 'settled') {
      payStatus = _PayStatus.settled;
    } else if (statusStr == 'pending') {
      payStatus = _PayStatus.pending;
    } else if (statusStr == 'overdue') {
      payStatus = _PayStatus.overdue;
    }

    return _PayRecord(
      label: json['label'] as String? ?? 'Payment',
      method: json['method'] as String? ?? 'Cash',
      date: json['date'] as String? ?? '—',
      ref: json['ref'] as String? ?? json['receiptNumber'] as String? ?? '—',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: payStatus,
    );
  }
}

class _DeviceLoan {
  final String? id;
  final String brand;
  final String model;
  final String storage;
  final String color;
  final String imei;
  final String saleType; // 'EMI' | 'CASH'
  final double principal;
  final double? sellingPrice;
  final double monthlyEmi;
  final int emiPaid;
  final int emiTotal;
  final bool isDefaulted;
  final String status;
  final String? notes;
  final String? emiPlanId;

  const _DeviceLoan({
    this.id,
    required this.brand,
    required this.model,
    required this.storage,
    required this.color,
    required this.imei,
    this.saleType = 'EMI',
    required this.principal,
    this.sellingPrice,
    required this.monthlyEmi,
    required this.emiPaid,
    required this.emiTotal,
    required this.isDefaulted,
    this.status = 'ACTIVE',
    this.notes,
    this.emiPlanId,
  });

  factory _DeviceLoan.fromJson(Map<String, dynamic> json) {
    final saleTypeStr =
        (json['saleType'] as String?)?.toUpperCase() ??
        ((json['monthlyEmi'] != null || json['monthlyInstallment'] != null)
            ? 'EMI'
            : 'CASH');
    return _DeviceLoan(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? json['modelName'] as String? ?? '',
      storage:
          json['storage'] as String? ??
          json['storageVariant'] as String? ??
          '—',
      color: json['color'] as String? ?? '—',
      imei: json['imei'] as String? ?? '',
      saleType: saleTypeStr,
      principal:
          (json['principal'] as num?)?.toDouble() ??
          (json['loanAmount'] as num?)?.toDouble() ??
          (json['sellingPrice'] as num?)?.toDouble() ??
          0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
      monthlyEmi:
          (json['monthlyEmi'] as num?)?.toDouble() ??
          (json['monthlyInstallment'] as num?)?.toDouble() ??
          0.0,
      emiPaid:
          (json['emiPaid'] as num?)?.toInt() ??
          (json['paidInstallments'] as num?)?.toInt() ??
          0,
      emiTotal:
          (json['emiTotal'] as num?)?.toInt() ??
          (json['totalEmiMonths'] as num?)?.toInt() ??
          (json['tenureMonths'] as num?)?.toInt() ??
          0,
      isDefaulted:
          json['isDefaulted'] as bool? ??
          (json['status'] == 'OVERDUE' ||
              ((json['overdueDays'] as num?)?.toInt() ?? 0) > 0),
      status:
          json['status'] as String? ??
          (saleTypeStr == 'CASH' ? 'CASH' : 'ACTIVE'),
      notes: json['notes'] as String?,
      emiPlanId: json['emiPlanId']?.toString() ?? json['planId']?.toString(),
    );
  }
}

class _CustomerProfile {
  final String id;
  final String name;
  final String initials;
  final String phone;
  final String address;
  final String memberSince;
  final bool isActive;
  final int trustScore;
  final double totalPurchases;
  final int deviceCount;
  final double totalRecovered;
  final String recoveryMethod;
  final double overdueAmount;
  final int overdueDays;
  final double upcomingInstallment;
  final String upcomingDate;
  final _DeviceLoan? activeLoan;
  final List<_DeviceLoan> devices;
  final List<_PayRecord> paymentHistory;

  const _CustomerProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.phone,
    required this.address,
    required this.memberSince,
    required this.isActive,
    required this.trustScore,
    required this.totalPurchases,
    required this.deviceCount,
    required this.totalRecovered,
    required this.recoveryMethod,
    required this.overdueAmount,
    required this.overdueDays,
    required this.upcomingInstallment,
    required this.upcomingDate,
    this.activeLoan,
    required this.devices,
    required this.paymentHistory,
  });

  factory _CustomerProfile.fromJson(Map<String, dynamic> json) {
    final List<_DeviceLoan> devicesList = [];
    final handsetsList = json['handsets'] as List<dynamic>? ?? [];
    final emiPlansList = json['emiPlans'] as List<dynamic>? ?? [];
    final Set<String> matchedPlanIds = {};

    // 1. Process all handsets from backend
    for (final hRaw in handsetsList) {
      if (hRaw is! Map<String, dynamic>) continue;
      final h = hRaw;
      final hEmiPlanId = h['emiPlanId']?.toString();
      final hImei = h['imei']?.toString().trim();

      // Find matching EMI plan if any
      Map<String, dynamic>? matchingPlan;
      if (hEmiPlanId != null && hEmiPlanId.isNotEmpty) {
        for (final pRaw in emiPlansList) {
          if (pRaw is! Map<String, dynamic>) continue;
          final pId = pRaw['id']?.toString() ?? pRaw['planId']?.toString();
          if (pId == hEmiPlanId) {
            matchingPlan = pRaw;
            if (pId != null) matchedPlanIds.add(pId);
            break;
          }
        }
      }

      if (matchingPlan == null && hImei != null && hImei.isNotEmpty) {
        for (final pRaw in emiPlansList) {
          if (pRaw is! Map<String, dynamic>) continue;
          final pId = pRaw['id']?.toString() ?? pRaw['planId']?.toString();
          final pH = pRaw['handset'] as Map<String, dynamic>?;
          final pImei = (pH?['imei'] ?? pRaw['imei'])?.toString().trim();
          if (pImei == hImei) {
            matchingPlan = pRaw;
            if (pId != null) matchedPlanIds.add(pId);
            break;
          }
        }
      }

      final isCash =
          (h['saleType']?.toString().toUpperCase() == 'CASH') ||
          (matchingPlan == null && (hEmiPlanId == null || hEmiPlanId.isEmpty));

      if (matchingPlan != null) {
        final pH = matchingPlan['handset'] as Map<String, dynamic>?;
        devicesList.add(
          _DeviceLoan(
            id: h['id']?.toString() ?? matchingPlan['id']?.toString(),
            brand:
                (h['brand']?.toString().isNotEmpty == true
                        ? h['brand']
                        : pH?['brand'])
                    ?.toString() ??
                '',
            model:
                (h['modelName']?.toString().isNotEmpty == true
                        ? h['modelName']
                        : (pH?['modelName'] ?? matchingPlan['deviceName']))
                    ?.toString() ??
                '',
            storage:
                (h['storageVariant']?.toString().isNotEmpty == true
                        ? h['storageVariant']
                        : pH?['storage'])
                    ?.toString() ??
                '—',
            color:
                (h['color']?.toString().isNotEmpty == true
                        ? h['color']
                        : pH?['color'])
                    ?.toString() ??
                '—',
            imei:
                (h['imei']?.toString().isNotEmpty == true
                        ? h['imei']
                        : (pH?['imei'] ?? matchingPlan['imei']))
                    ?.toString() ??
                '',
            saleType: 'EMI',
            principal:
                (matchingPlan['loanAmount'] as num?)?.toDouble() ??
                (matchingPlan['sellingPrice'] as num?)?.toDouble() ??
                (h['sellingPrice'] as num?)?.toDouble() ??
                0.0,
            sellingPrice:
                (h['sellingPrice'] as num?)?.toDouble() ??
                (matchingPlan['sellingPrice'] as num?)?.toDouble(),
            monthlyEmi:
                (matchingPlan['monthlyInstallment'] as num?)?.toDouble() ?? 0.0,
            emiPaid: (matchingPlan['paidInstallments'] as num?)?.toInt() ?? 0,
            emiTotal:
                (matchingPlan['tenureMonths'] as num?)?.toInt() ??
                (matchingPlan['totalEmiMonths'] as num?)?.toInt() ??
                0,
            isDefaulted:
                matchingPlan['status'] == 'OVERDUE' ||
                ((matchingPlan['overdueDays'] as num?)?.toInt() ?? 0) > 0,
            status: matchingPlan['status']?.toString() ?? 'ON_TRACK',
            notes: h['notes']?.toString(),
            emiPlanId:
                matchingPlan['id']?.toString() ??
                matchingPlan['planId']?.toString(),
          ),
        );
      } else {
        devicesList.add(
          _DeviceLoan(
            id: h['id']?.toString(),
            brand: h['brand']?.toString() ?? '',
            model: h['modelName']?.toString() ?? '',
            storage: h['storageVariant']?.toString() ?? '—',
            color: h['color']?.toString() ?? '—',
            imei: h['imei']?.toString() ?? '',
            saleType: isCash ? 'CASH' : 'EMI',
            principal: (h['sellingPrice'] as num?)?.toDouble() ?? 0.0,
            sellingPrice: (h['sellingPrice'] as num?)?.toDouble() ?? 0.0,
            monthlyEmi: 0.0,
            emiPaid: 0,
            emiTotal: 0,
            isDefaulted: false,
            status: isCash ? 'CASH' : 'ACTIVE',
            notes: h['notes']?.toString(),
            emiPlanId: null,
          ),
        );
      }
    }

    // 2. Add any unmatched EMI plans
    for (final pRaw in emiPlansList) {
      if (pRaw is! Map<String, dynamic>) continue;
      final pId = pRaw['id']?.toString() ?? pRaw['planId']?.toString();
      if (pId != null && matchedPlanIds.contains(pId)) continue;

      final pH = pRaw['handset'] as Map<String, dynamic>?;
      devicesList.add(
        _DeviceLoan(
          id: pId,
          brand: pH?['brand']?.toString() ?? pRaw['brand']?.toString() ?? '',
          model:
              pH?['modelName']?.toString() ??
              pRaw['modelName']?.toString() ??
              pRaw['deviceName']?.toString() ??
              '',
          storage:
              pH?['storage']?.toString() ?? pRaw['storage']?.toString() ?? '—',
          color: pH?['color']?.toString() ?? pRaw['color']?.toString() ?? '—',
          imei: pH?['imei']?.toString() ?? pRaw['imei']?.toString() ?? '',
          saleType: 'EMI',
          principal:
              (pRaw['loanAmount'] as num?)?.toDouble() ??
              (pRaw['sellingPrice'] as num?)?.toDouble() ??
              0.0,
          sellingPrice: (pRaw['sellingPrice'] as num?)?.toDouble(),
          monthlyEmi: (pRaw['monthlyInstallment'] as num?)?.toDouble() ?? 0.0,
          emiPaid: (pRaw['paidInstallments'] as num?)?.toInt() ?? 0,
          emiTotal:
              (pRaw['tenureMonths'] as num?)?.toInt() ??
              (pRaw['totalEmiMonths'] as num?)?.toInt() ??
              0,
          isDefaulted:
              pRaw['status'] == 'OVERDUE' ||
              ((pRaw['overdueDays'] as num?)?.toInt() ?? 0) > 0,
          status: pRaw['status']?.toString() ?? 'ON_TRACK',
          notes: null,
          emiPlanId: pId,
        ),
      );
    }

    // 3. Fallback to activeLoan if devicesList is still empty
    if (devicesList.isEmpty) {
      Map<String, dynamic>? activeLoanJson =
          json['activeLoan'] as Map<String, dynamic>?;
      if (activeLoanJson == null && emiPlansList.isNotEmpty) {
        final p = emiPlansList.first as Map<String, dynamic>;
        final h = p['handset'] as Map<String, dynamic>?;
        activeLoanJson = {
          'id': p['id'] ?? p['planId'],
          'brand': h?['brand'] ?? p['brand'] ?? '',
          'model': h?['modelName'] ?? p['modelName'] ?? p['deviceName'] ?? '',
          'storage': h?['storage'] ?? p['storage'] ?? '—',
          'color': h?['color'] ?? p['color'] ?? '—',
          'imei': p['imei'] ?? h?['imei'] ?? '',
          'principal': p['loanAmount'] ?? p['sellingPrice'] ?? 0,
          'monthlyEmi': p['monthlyInstallment'] ?? p['installmentAmount'] ?? 0,
          'emiPaid': p['paidInstallments'] ?? p['currentEmiNumber'] ?? 0,
          'emiTotal': p['totalEmiMonths'] ?? p['tenureMonths'] ?? 0,
          'isDefaulted':
              (p['status'] == 'OVERDUE' ||
              ((p['overdueDays'] as num?)?.toInt() ?? 0) > 0),
        };
      }
      if (activeLoanJson != null) {
        devicesList.add(_DeviceLoan.fromJson(activeLoanJson));
      }
    }

    _DeviceLoan? activeLoan;
    if (json['activeLoan'] is Map<String, dynamic>) {
      activeLoan = _DeviceLoan.fromJson(
        json['activeLoan'] as Map<String, dynamic>,
      );
    } else {
      activeLoan =
          devicesList
              .where((d) => d.saleType == 'EMI' && d.status != 'CLEARED')
              .firstOrNull ??
          devicesList.firstOrNull;
    }

    final nameStr =
        json['name'] as String? ?? json['fullName'] as String? ?? 'Customer';
    final initialsStr =
        json['initials'] as String? ??
        (nameStr.trim().isNotEmpty
            ? nameStr
                  .trim()
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase()
            : '?');

    final payHistory = (json['paymentHistory'] as List<dynamic>? ?? [])
        .map((e) => _PayRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    return _CustomerProfile(
      id: json['id'] as String? ?? json['_id']?.toString() ?? '',
      name: nameStr,
      initials: initialsStr,
      phone: json['phone'] as String? ?? json['mobileNumber'] as String? ?? '—',
      address: json['address'] as String? ?? '—',
      memberSince: json['memberSince'] as String? ?? 'Oct 2026',
      isActive: json['isActive'] as bool? ?? true,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 100,
      totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0.0,
      deviceCount: (json['deviceCount'] as num?)?.toInt() ?? devicesList.length,
      totalRecovered: (json['totalRecovered'] as num?)?.toDouble() ?? 0.0,
      recoveryMethod: json['recoveryMethod'] as String? ?? 'Via Cash & UPI',
      overdueAmount: (json['overdueAmount'] as num?)?.toDouble() ?? 0.0,
      overdueDays: (json['overdueDays'] as num?)?.toInt() ?? 0,
      upcomingInstallment:
          (json['upcomingInstallment'] as num?)?.toDouble() ?? 0.0,
      upcomingDate: json['upcomingDate'] as String? ?? '—',
      activeLoan: activeLoan,
      devices: devicesList,
      paymentHistory: payHistory,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PAGE
// ═════════════════════════════════════════════════════════════════════════════

/// Customer Profile page — receives [customerId] as a route parameter.
class CustomerDetailsPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() {
    _detailsFuture = sl<CustomerRepository>().getCustomerDetails(
      widget.customerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoader());
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Customer Profile'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: AppErrorView(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _fetchDetails();
                });
              },
            ),
          );
        }

        final res = snapshot.data;
        if (res == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Profile')),
            body: const AppEmptyView(message: 'Customer profile not found'),
          );
        }

        final data = (res['data'] is Map<String, dynamic>)
            ? res['data'] as Map<String, dynamic>
            : res;

        final profile = _CustomerProfile.fromJson(data);
        return _CustomerProfileView(profile: profile);
      },
    );
  }
}

class _CustomerProfileView extends StatelessWidget {
  final _CustomerProfile profile;

  const _CustomerProfileView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Scaffold(
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // ── Hero header ───────────────────────────────────────────────────
          _heroHeader(context, fmt),
          const SizedBox(height: 12),

          // ── Khata Summary ─────────────────────────────────────────────────
          _khataCard(context, fmt),
          const SizedBox(height: 12),

          // ── Overdue banner (shown only when overdue > 0) ──────────────────
          if (profile.overdueAmount > 0) ...[
            _overdueBanner(context, fmt),
            const SizedBox(height: 12),
          ],

          // ── Active Loan & Device ──────────────────────────────────────────
          _activeLoanCard(context, fmt),
          const SizedBox(height: 12),

          // ── Payment History ───────────────────────────────────────────────
          _paymentHistoryCard(context, fmt),
        ],
      ),
      bottomNavigationBar: _addPurchaseButton(context),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : _kCardBg,
          boxShadow: isDark
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RoutePaths.customers);
                  }
                },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: textColor,
                ),
              ),
              Expanded(
                child: Text(
                  'Customer Profile',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero Header ─────────────────────────────────────────────────────────
  Widget _heroHeader(BuildContext context, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : _kGrey;

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF9B8FF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    profile.initials,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + phone + address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        _statusBadge(profile.isActive),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 12,
                          color: _kGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.phone,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: _kPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          profile.address,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Since ${profile.memberSince}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: _actionBtn(
              icon: Icons.call_rounded,
              label: 'Call Customer',
              bg: _kBlueDark,
              fg: Colors.white,
              onTap: () async {
                final phone = profile.phone.replaceAll(RegExp(r'\D'), '');
                final url = Uri.parse('tel:+$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _kGreenLight : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? _kGreen : _kGrey,
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Khata Summary ───────────────────────────────────────────────────────
  Widget _khataCard(BuildContext context, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : _kGrey;

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'KHATA SUMMARY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: secondaryTextColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? _kGreen.withValues(alpha: 0.2) : _kGreenLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, size: 10, color: _kGreen),
                    const SizedBox(width: 3),
                    Text(
                      'Trust Score: ${profile.trustScore}/100',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _khataStatCol(
                  context,
                  label: 'Total Purchases',
                  value: '₹${fmt.format(profile.totalPurchases)}',
                  sub: '${profile.deviceCount} Devices Total',
                  valueColor: primaryTextColor,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark ? AppColors.borderDark : _kBorder,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _khataStatCol(
                    context,
                    label: 'Total Recovered',
                    value: '₹${fmt.format(profile.totalRecovered)}',
                    sub: profile.recoveryMethod,
                    valueColor: _kGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _khataStatCol(
    BuildContext context, {
    required String label,
    required String value,
    required String sub,
    required Color valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : _kGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: secondaryTextColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: valueColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: GoogleFonts.inter(fontSize: 10, color: secondaryTextColor),
        ),
      ],
    );
  }

  // ─── Overdue Banner ──────────────────────────────────────────────────────
  Widget _overdueBanner(BuildContext context, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : _kGrey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withValues(alpha: 0.15) : _kRedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: _kRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'OVERDUE BY ${profile.overdueDays} DAYS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kRed,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${fmt.format(profile.overdueAmount)}',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _kRed,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Upcoming Installment',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.upcomingDate,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Active Loan & Device ────────────────────────────────────────────────
  Widget _activeLoanCard(BuildContext context, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : _kGrey;

    final devices = profile.devices;
    if (devices.isEmpty) {
      return _card(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : _kGreyLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  size: 18,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'No devices registered for this customer',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasDefaulted = devices.any((d) => d.isDefaulted);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 15,
                color: primaryTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                devices.length > 1
                    ? 'Active Loans & Devices'
                    : 'Active Loan & Device',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const Spacer(),
              if (hasDefaulted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withValues(alpha: 0.2)
                        : _kRedLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 10,
                        color: _kRed,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'EMI Defaulted',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                        ),
                      ),
                    ],
                  ),
                )
              else if (devices.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? _kPurple.withValues(alpha: 0.2)
                        : _kPurpleLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${devices.length} Handsets',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kPurple,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Handset entries
          for (int i = 0; i < devices.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 16),
            ],
            _deviceItem(context, devices[i], i + 1, devices.length, fmt),
          ],
        ],
      ),
    );
  }

  Widget _deviceItem(
    BuildContext context,
    _DeviceLoan loan,
    int index,
    int totalCount,
    NumberFormat fmt,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : _kGrey;

    final isCash = loan.saleType == 'CASH';
    final double progress = (loan.emiTotal > 0)
        ? (loan.emiPaid / loan.emiTotal).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Index & Status row
        Row(
          children: [
            if (totalCount > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Handset #$index',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            const Spacer(),
            if (isCash)
              _buildStatusBadge(
                label: 'Cash Purchase',
                icon: Icons.check_circle_outline_rounded,
                color: _kGreen,
                bg: isDark ? _kGreen.withValues(alpha: 0.2) : _kGreenLight,
              )
            else if (loan.isDefaulted)
              _buildStatusBadge(
                label: 'EMI Defaulted',
                icon: Icons.error_outline_rounded,
                color: _kRed,
                bg: isDark ? _kRed.withValues(alpha: 0.2) : _kRedLight,
              )
            else if (loan.status == 'CLEARED')
              _buildStatusBadge(
                label: 'Loan Cleared',
                icon: Icons.verified_rounded,
                color: _kGreen,
                bg: isDark ? _kGreen.withValues(alpha: 0.2) : _kGreenLight,
              )
            else
              _buildStatusBadge(
                label: 'EMI Active',
                icon: Icons.schedule_rounded,
                color: _kPurple,
                bg: isDark ? _kPurple.withValues(alpha: 0.2) : _kPurpleLight,
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Device tile
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : _kGreyLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primary : _kBlueDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loan.brand} ${loan.model}'.trim().isNotEmpty
                          ? '${loan.brand} ${loan.model}'.trim()
                          : 'Handset Device',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      '${loan.storage} • ${loan.color}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IMEI: ${loan.imei.isNotEmpty ? loan.imei : '—'}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: secondaryTextColor,
                      ),
                    ),
                    if (loan.notes != null && loan.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Note: ${loan.notes}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Financials & Actions
        if (isCash) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? _kGreen.withValues(alpha: 0.1) : _kGreenLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _kGreen.withValues(alpha: isDark ? 0.3 : 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: _kGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cash Sale (Paid in Full)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kGreen,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${fmt.format(loan.sellingPrice ?? loan.principal)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 14),

          // Installment Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Installment Progress',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
              Text(
                loan.status == 'CLEARED'
                    ? 'All ${loan.emiTotal} EMIs Cleared'
                    : 'EMI #${loan.emiPaid} of ${loan.emiTotal}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: loan.status == 'CLEARED' ? _kGreen : _kPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.borderDark : _kBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                loan.status == 'CLEARED' ? _kGreen : _kPurple,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Loan Principal: ₹${fmt.format(loan.principal)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
              const Spacer(),
              Text(
                'Monthly: ₹${fmt.format(loan.monthlyEmi)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () async {
                await context.push(
                  RoutePaths.recordPayment,
                  extra: {
                    'customerId': profile.id,
                    'emiPlanId': loan.emiPlanId,
                  },
                );
                sl<DashboardBloc>().add(const LoadDashboard());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primary : _kBlueDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.payments_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Record Payment',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment History ─────────────────────────────────────────────────────
  Widget _paymentHistoryCard(BuildContext context, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Payment History',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? _kPurple.withValues(alpha: 0.2)
                      : _kPurpleLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${profile.paymentHistory.length} Records',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...profile.paymentHistory.asMap().entries.map((entry) {
            final i = entry.key;
            final rec = entry.value;
            return Column(
              children: [
                _paymentRow(context, rec, fmt),
                if (i < profile.paymentHistory.length - 1) ...[
                  const SizedBox(height: 2),
                  Divider(
                    height: 12,
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFF1F5F9),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _paymentRow(BuildContext context, _PayRecord rec, NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : _kBlueDark;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : _kGrey;

    final (icon, iconBg, statusLabel, statusColor, amountColor) = _statusAssets(
      rec.status,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? iconBg.withValues(alpha: 0.2) : iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, size: 18, color: statusColor)),
          ),
          const SizedBox(width: 10),

          // Label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rec.date}  •  Rec. #${rec.ref}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: secondaryTextColor,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.payment_rounded,
                      size: 10,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rec.method,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+₹${fmt.format(rec.amount)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? iconBg.withValues(alpha: 0.2) : iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns (icon, iconBg, statusLabel, statusColor, amountColor)
  (IconData, Color, String, Color, Color) _statusAssets(_PayStatus status) {
    switch (status) {
      case _PayStatus.paid:
        return (
          Icons.check_circle_rounded,
          _kGreenLight,
          'Success',
          _kGreen,
          _kGreen,
        );
      case _PayStatus.pending:
        return (
          Icons.schedule_rounded,
          _kAmberLight,
          'Pending',
          _kAmber,
          _kAmber,
        );
      case _PayStatus.overdue:
        return (
          Icons.warning_amber_rounded,
          _kRedLight,
          'Overdue',
          _kRed,
          _kRed,
        );
      case _PayStatus.settled:
        return (
          Icons.verified_rounded,
          _kPurpleLight,
          'Settled',
          _kPurple,
          _kPurple,
        );
    }
  }

  // ─── Bottom CTA ──────────────────────────────────────────────────────────
  Widget _addPurchaseButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kCardBg,
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push(RoutePaths.addEmi),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_circle_rounded, size: 20),
          label: Text(
            'Add Another Purchase / EMI',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ─── Card wrapper ────────────────────────────────────────────────────────
  Widget _card(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
