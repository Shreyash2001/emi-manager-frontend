import 'dart:async';
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
import 'package:mobile_emi_manager/features/payments/data/models/payment_models.dart';
import 'package:mobile_emi_manager/features/payments/domain/repositories/payment_repository.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryLight = Color(0xFFEEF2FF);
const _kSuccess = Color(0xFF10B981);
const _kSuccessLight = Color(0xFFECFDF5);
const _kDanger = Color(0xFFEF4444);
const _kDangerLight = Color(0xFFFEF2F2);
const _kTextDark = Color(0xFF1E293B);
const _kTextGrey = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kBg = Color(0xFFF8FAFC);
const _kCardBg = Color(0xFFFFFFFF);

// ─── Data Models ─────────────────────────────────────────────────────────────
class _HandsetOption {
  final String id; // emiPlanId
  final String model;
  final String storage;
  final String imei;
  final String loanNo;
  final int instCurrent;
  final int instTotal;
  final double monthlyDue;
  final String dueDate;
  final String dueStatus;
  final String status;
  final double outstandingAmount;

  const _HandsetOption({
    required this.id,
    required this.model,
    required this.storage,
    required this.imei,
    required this.loanNo,
    required this.instCurrent,
    required this.instTotal,
    required this.monthlyDue,
    required this.dueDate,
    required this.dueStatus,
    this.status = 'ON_TRACK',
    this.outstandingAmount = 0.0,
  });
}

class _CustomerOption {
  final String id;
  final String name;
  final String initials;
  final String phone;
  final String kycStatus;
  final List<_HandsetOption> handsets;

  const _CustomerOption({
    required this.id,
    required this.name,
    required this.initials,
    required this.phone,
    required this.kycStatus,
    required this.handsets,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// RECORD PAYMENT PAGE
// ═════════════════════════════════════════════════════════════════════════════
class RecordPaymentPage extends StatefulWidget {
  final String? initialCustomerId;
  final String? initialEmiPlanId;

  const RecordPaymentPage({
    super.key,
    this.initialCustomerId,
    this.initialEmiPlanId,
  });

  @override
  State<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends State<RecordPaymentPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<_CustomerOption> _customers = [];
  _CustomerOption? _selectedCustomer;
  _HandsetOption? _selectedHandset;
  PaymentModel? _recordedPayment;

  late TextEditingController _amountController;
  final TextEditingController _transactionRefController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selected Payment Mode: 0: Cash Counter, 1: UPI / QR Scan, 2: Card POS Swipe, 3: Bank / NEFT / IMPS
  int _selectedPaymentMode = 1;

  // Date and Time
  DateTime _collectionDate = DateTime.now();
  TimeOfDay _collectionTime = TimeOfDay.now();

  // Submission / Success Overlay State
  bool _isSubmitting = false;
  bool _isSuccess = false;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '0');
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionRefController.dispose();
    _notesController.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  String _formatCurrency(double val) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return fmt.format(val);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await sl<CustomerRepository>().listCustomers(page: 1, limit: 100);
      final customerOptions = <_CustomerOption>[];

      for (final item in res.items) {
        final handsets = <_HandsetOption>[];

        // 1. Process plans from emiPlans
        if (item.emiPlans != null && item.emiPlans!.isNotEmpty) {
          for (final pRaw in item.emiPlans!) {
            if (pRaw is! Map<String, dynamic>) continue;
            final p = pRaw;
            final pId = p['id']?.toString() ?? p['planId']?.toString() ?? '';
            final h = p['handset'] as Map<String, dynamic>?;
            final brand = h?['brand']?.toString() ?? '';
            final modelName = h?['modelName']?.toString() ?? p['deviceName']?.toString() ?? 'Device';
            final fullModel = '$brand $modelName'.trim();
            final storage = h?['storage']?.toString() ?? h?['storageVariant']?.toString() ?? '—';
            final imei = h?['imei']?.toString() ?? p['imei']?.toString() ?? '—';
            final loanIdShort = pId.length > 6 ? pId.substring(pId.length - 6).toUpperCase() : pId;
            final loanNo = '#EMI-$loanIdShort';
            final instCurrent = (p['currentEmiNumber'] as num?)?.toInt() ??
                (((p['paidInstallments'] as num?)?.toInt() ?? 0) + 1);
            final instTotal = (p['tenureMonths'] as num?)?.toInt() ??
                ((p['totalEmiMonths'] as num?)?.toInt() ?? 1);
            final monthlyDue = (p['monthlyInstallment'] as num?)?.toDouble() ??
                ((p['installmentAmount'] as num?)?.toDouble() ?? 0.0);

            String dueDateStr = '—';
            if (p['nextDueDate'] != null) {
              final dt = DateTime.tryParse(p['nextDueDate'].toString());
              if (dt != null) {
                dueDateStr = DateFormat('dd MMM yyyy').format(dt);
              }
            } else if (item.nextDueDateLabel != null) {
              dueDateStr = item.nextDueDateLabel!;
            }

            final status = p['status']?.toString() ?? 'ON_TRACK';
            final dueStatus = p['dueStatusLabel']?.toString() ??
                (status == 'OVERDUE'
                    ? 'Overdue'
                    : (status == 'CLEARED' ? 'Cleared' : 'On Track'));

            handsets.add(_HandsetOption(
              id: pId,
              model: fullModel.isNotEmpty ? fullModel : 'Smartphone',
              storage: storage,
              imei: imei,
              loanNo: loanNo,
              instCurrent: instCurrent,
              instTotal: instTotal,
              monthlyDue: monthlyDue,
              dueDate: dueDateStr,
              dueStatus: dueStatus,
              status: status,
              outstandingAmount: (p['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
            ));
          }
        }

        // 2. Fallback if emiPlans is empty but item has active installment
        if (handsets.isEmpty && item.installmentAmount != null && item.installmentAmount! > 0) {
          handsets.add(_HandsetOption(
            id: item.id,
            model: item.deviceName ?? 'Device',
            storage: '—',
            imei: item.imei ?? '—',
            loanNo: '#EMI-${item.id.length > 6 ? item.id.substring(item.id.length - 6).toUpperCase() : item.id}',
            instCurrent: item.currentEmiNumber ?? 1,
            instTotal: item.totalEmiMonths ?? 12,
            monthlyDue: item.installmentAmount ?? 0.0,
            dueDate: item.nextDueDateLabel ?? '—',
            dueStatus: item.status == 'OVERDUE' ? 'Overdue' : 'On Track',
            status: item.status ?? 'ON_TRACK',
            outstandingAmount: item.outstandingAmount ?? 0.0,
          ));
        }

        final initials = item.name.trim().isNotEmpty
            ? item.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
            : '?';

        customerOptions.add(_CustomerOption(
          id: item.id,
          name: item.name,
          initials: initials,
          phone: item.mobileNumber,
          kycStatus: 'KYC OK',
          handsets: handsets,
        ));
      }

      // Prioritize customers who have active handsets
      final emiCustomers = customerOptions.where((c) => c.handsets.isNotEmpty).toList();
      _customers = emiCustomers.isNotEmpty ? emiCustomers : customerOptions;

      if (_customers.isNotEmpty) {
        _CustomerOption selectedCust = _customers.first;
        if (widget.initialCustomerId != null) {
          final found = _customers.where((c) => c.id == widget.initialCustomerId).firstOrNull;
          if (found != null) selectedCust = found;
        }
        _selectedCustomer = selectedCust;

        if (selectedCust.handsets.isNotEmpty) {
          _HandsetOption selectedHandset = selectedCust.handsets.first;
          if (widget.initialEmiPlanId != null) {
            final foundH = selectedCust.handsets.where((h) => h.id == widget.initialEmiPlanId).firstOrNull;
            if (foundH != null) selectedHandset = foundH;
          }
          _selectedHandset = selectedHandset;
          _amountController.text = _formatCurrency(selectedHandset.monthlyDue);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onCustomerChanged(_CustomerOption customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer.handsets.isNotEmpty) {
        _selectedHandset = customer.handsets[0];
        _amountController.text = _formatCurrency(_selectedHandset!.monthlyDue);
      } else {
        _selectedHandset = null;
        _amountController.text = '0';
      }
    });
  }

  void _onHandsetChanged(_HandsetOption handset) {
    setState(() {
      _selectedHandset = handset;
      _amountController.text = _formatCurrency(handset.monthlyDue);
    });
  }

  Future<void> _onRecordPayment() async {
    if (_selectedCustomer == null || _selectedHandset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer and an active loan.')),
      );
      return;
    }

    final rawAmountText = _amountController.text.replaceAll(',', '').replaceAll('₹', '').trim();
    final amount = double.tryParse(rawAmountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount greater than 0.')),
      );
      return;
    }

    // Map UI mode to backend enum: CASH, UPI, CARD, UPI_AUTOPAY
    final paymentMethods = ['CASH', 'UPI', 'CARD', 'UPI_AUTOPAY'];
    final paymentMethod = (_selectedPaymentMode >= 0 && _selectedPaymentMode < paymentMethods.length)
        ? paymentMethods[_selectedPaymentMode]
        : 'UPI';

    final paymentDateTime = DateTime(
      _collectionDate.year,
      _collectionDate.month,
      _collectionDate.day,
      _collectionTime.hour,
      _collectionTime.minute,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = RecordPaymentRequestModel(
        customerId: _selectedCustomer!.id,
        emiPlanId: _selectedHandset!.id,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentType: 'EMI',
        installmentNumber: _selectedHandset!.instCurrent,
        paymentDate: paymentDateTime.toIso8601String(),
        transactionReference: _transactionRefController.text.trim().isNotEmpty
            ? _transactionRefController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final result = await sl<PaymentRepository>().recordPayment(request);

      // Trigger immediate background refresh of dashboard data
      sl<DashboardBloc>().add(const LoadDashboard());

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _recordedPayment = result;
        _isSuccess = true;
      });

      _redirectTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          sl<DashboardBloc>().add(const LoadDashboard());
          context.go(RoutePaths.dashboard);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: _kDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: AppLoader()),
      );
    }

    if (_errorMessage != null && _customers.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: AppErrorView(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    if (_customers.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: AppEmptyView(
          message: 'No customers found with active EMI plans.',
          onAction: _loadData,
          actionLabel: 'Refresh',
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              // ── 1. Customer & Handset Info Section ────────────────────────
              _buildCustomerCard(),
              const SizedBox(height: 12),
              _buildHandsetCard(),
              const SizedBox(height: 12),
              _buildDueSummaryRow(),
              const SizedBox(height: 16),

              // ── 2. Amount Received Card ───────────────────────────────────
              _buildAmountCard(),
              const SizedBox(height: 16),

              // ── 3. Payment Mode Grid ──────────────────────────────────────
              _buildPaymentModeGrid(),
              const SizedBox(height: 16),

              // ── 4. Collection Timing Section ──────────────────────────────
              _buildCollectionTimingSection(context),
            ],
          ),

          // ── Bottom Fixed Button ───────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCTA(context),
          ),

          // ── Success Overlay View ─────────────────────────────────────────
          if (_isSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : _kCardBg,
          boxShadow: isDark
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RoutePaths.dashboard);
                    }
                  },
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : _kBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        size: 20, color: isDark ? Colors.white : _kTextDark),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Record EMI Payment',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : _kTextDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'COLLECT',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Counter POS • Quick Record',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _kTextGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. CUSTOMER CARD ─────────────────────────────────────────────────────
  Widget _buildCustomerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cust = _selectedCustomer;
    if (cust == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCustomerSelectionSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : _kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Initials Avatar
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cust.initials,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _kSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Name, Phone & KYC Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cust.name,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : _kTextDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : _kBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: isDark ? AppColors.borderDark : _kBorder),
                          ),
                          child: Text(
                            cust.kycStatus,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kTextGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          cust.phone,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _kTextGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 13, color: _kSuccess),
                      ],
                    ),
                  ],
                ),
              ),

              // Change Customer Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        size: 14, color: _kPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'Change',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 2. HANDSET CARD ──────────────────────────────────────────────────────
  Widget _buildHandsetCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final handset = _selectedHandset;
    if (handset == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : _kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
        ),
        child: Text(
          'No active EMI handsets for this customer',
          style: GoogleFonts.inter(fontSize: 13, color: _kTextGrey),
        ),
      );
    }

    final hasHandsets = (_selectedCustomer?.handsets.isNotEmpty ?? false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasHandsets ? () => _showHandsetSelectionSheet(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark
                : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4338CA).withValues(alpha: 0.6)
                  : const Color(0xFFC7D2FE),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      size: 20,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Model & Storage
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          handset.model,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : _kTextDark,
                          ),
                        ),
                        Text(
                          handset.storage,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _kTextGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Installment Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Inst. #${handset.instCurrent} of ${handset.instTotal}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),

                  if (hasHandsets) ...[
                    const SizedBox(width: 8),
                    // Prominent, larger, distinct color dropdown icon
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isDark ? const Color(0xFF6366F1) : const Color(0xFF818CF8),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                        size: 26,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                  height: 1, color: isDark ? AppColors.borderDark : _kBorder),
              const SizedBox(height: 8),

              // Subtext row IMEI & Loan ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IMEI: ${handset.imei}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _kTextGrey,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'Loan ${handset.loanNo}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : _kTextDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 3. DUE SUMMARY ROW ───────────────────────────────────────────────────
  Widget _buildDueSummaryRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final handset = _selectedHandset;
    if (handset == null) return const SizedBox.shrink();

    final isOverdue = handset.dueStatus.toLowerCase().contains('overdue');

    return Row(
      children: [
        // Monthly Due Box
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : _kBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONTHLY DUE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: _kTextGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatCurrency(handset.monthlyDue)}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : _kTextDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Due Date Box
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : _kBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DUE DATE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: _kTextGrey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOverdue ? _kDangerLight : _kPrimaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isOverdue ? _kDanger : _kPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            handset.dueStatus,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isOverdue ? _kDanger : _kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  handset.dueDate,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _kTextDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  // ─── 2. AMOUNT CARD ───────────────────────────────────────────────────────
  Widget _buildAmountCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                'Amount Received',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _kTextDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kSuccessLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Regular Installment',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : _kBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
            ),
            child: Row(
              children: [
                Text(
                  '₹ ',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _kTextDark,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _kTextDark,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Icon(Icons.edit_rounded,
                    size: 20, color: _kTextGrey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. PAYMENT MODE GRID ─────────────────────────────────────────────────
  Widget _buildPaymentModeGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final modes = [
      {
        'title': 'Cash Counter',
        'sub': 'Direct Cash Box',
        'icon': Icons.payments_outlined,
      },
      {
        'title': 'UPI / QR Scan',
        'sub': 'GPay, PhonePe, Paytm',
        'icon': Icons.qr_code_scanner_rounded,
      },
      {
        'title': 'Card POS Swipe',
        'sub': 'PineLabs / MSwipe',
        'icon': Icons.credit_card_rounded,
      },
      {
        'title': 'Bank / AutoPay',
        'sub': 'Direct Mandate / NEFT',
        'icon': Icons.account_balance_outlined,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                'Payment Mode',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _kTextDark,
                ),
              ),
              Text(
                'Instant clearance',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _kTextGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final mode = modes[index];
              final isSelected = _selectedPaymentMode == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedPaymentMode = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPrimary
                        : (isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? _kPrimary
                          : (isDark ? AppColors.borderDark : _kBorder),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mode['icon'] as IconData,
                        size: 22,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : _kTextDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mode['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : _kTextDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode['sub'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : _kTextGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── 7. COLLECTION TIMING SECTION ─────────────────────────────────────────
  Widget _buildCollectionTimingSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeStr = _collectionTime.format(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                'Collection Timing',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _kTextDark,
                ),
              ),
              Text(
                'Timestamp recorded',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _kTextGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection Date',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _kTextGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _collectionDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _collectionDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDark ? AppColors.borderDark : _kBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 16, color: _kPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateFormat.format(_collectionDate),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : _kTextDark,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: _kTextGrey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Time Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection Time',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _kTextGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _collectionTime,
                        );
                        if (picked != null) {
                          setState(() => _collectionTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDark ? AppColors.borderDark : _kBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 16, color: _kPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                timeStr,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : _kTextDark,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: _kTextGrey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Optional Reference & Notes Fields
          Text(
            'Reference / UTR No. (Optional)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _kTextGrey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
            ),
            child: TextField(
              controller: _transactionRefController,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark ? Colors.white : _kTextDark,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. UPI-REC-001 or UTR number',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Notes (Optional)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _kTextGrey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
            ),
            child: TextField(
              controller: _notesController,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark ? Colors.white : _kTextDark,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. Paid in full for month',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 8. BOTTOM CTA BUTTON ─────────────────────────────────────────────────
  Widget _buildBottomCTA(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kCardBg,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_isSubmitting || _selectedHandset == null)
                ? null
                : _onRecordPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Record Payment',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 20, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── 9. SUCCESS OVERLAY SCREEN ────────────────────────────────────────────
  Widget _buildSuccessOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _kSuccessLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _kSuccess,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Added Successfully!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Payment of ₹${_amountController.text} collected from ${_selectedCustomer?.name ?? 'Customer'}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _kTextGrey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : _kBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _recordedPayment?.receiptNumber != null &&
                          _recordedPayment!.receiptNumber!.isNotEmpty
                      ? 'Receipt #${_recordedPayment!.receiptNumber}'
                      : 'Payment Recorded',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Redirecting to Dashboard...',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _kTextGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BOTTOM SHEETS ────────────────────────────────────────────────────────
  void _showCustomerSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final filtered = _customers.where((c) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  c.phone.toLowerCase().contains(q);
            }).toList();

            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Select Customer',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : _kTextDark,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Search Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : _kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? AppColors.borderDark : _kBorder),
                    ),
                    child: TextField(
                      autofocus: false,
                      style: GoogleFonts.inter(
                          color: isDark ? Colors.white : _kTextDark),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search_rounded,
                            size: 20, color: _kTextGrey),
                        hintText: 'Search by name or phone...',
                        hintStyle: GoogleFonts.inter(color: _kTextGrey),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          searchQuery = val.trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No customers match "$searchQuery"',
                              style: GoogleFonts.inter(color: _kTextGrey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final cust = filtered[index];
                              final isSel = cust.id == _selectedCustomer?.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _kPrimaryLight,
                                  child: Text(
                                    cust.initials,
                                    style: GoogleFonts.inter(
                                      color: _kPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cust.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : _kTextDark,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cust.phone} • ${cust.handsets.length} Handset(s)',
                                  style: GoogleFonts.inter(color: _kTextGrey),
                                ),
                                trailing: isSel
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: _kPrimary)
                                    : null,
                                onTap: () {
                                  _onCustomerChanged(cust);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHandsetSelectionSheet(BuildContext context) {
    final handsets = _selectedCustomer?.handsets ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Handset / EMI Loan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _kTextDark,
                ),
              ),
              const SizedBox(height: 12),
              ...handsets.map((handset) {
                final isSel = handset.id == _selectedHandset?.id;
                return ListTile(
                  leading: const Icon(Icons.phone_android_rounded,
                      color: _kPrimary),
                  title: Text(
                    '${handset.model} (${handset.storage})',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _kTextDark,
                    ),
                  ),
                  subtitle: Text(
                    'Due: ₹${_formatCurrency(handset.monthlyDue)} • ${handset.dueDate}',
                    style: GoogleFonts.inter(color: _kTextGrey),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_circle_rounded,
                          color: _kPrimary)
                      : null,
                  onTap: () {
                    _onHandsetChanged(handset);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
