import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_emi_manager/app/router/route_paths.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/customers/data/models/customer_models.dart';
import 'package:mobile_emi_manager/features/customers/domain/repositories/customer_repository.dart';
import 'package:mobile_emi_manager/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// ─── Colour constants specific to this screen ────────────────────────────────
const _kPurple = Color(0xFF6C5CE7);
const _kPurpleLight = Color(0xFFF0EEFF);
const _kGreen = Color(0xFF00B894);
const _kGreenLight = Color(0xFFE6FAF6);
const _kRed = Color(0xFFE17055);
const _kBlueDark = Color(0xFF2D3748);
const _kGrey = Color(0xFF718096);
const _kGreyLight = Color(0xFFF7F8FA);
const _kBorder = Color(0xFFE2E8F0);
const _kCardBg = Color(0xFFFFFFFF);

// ─── Models ──────────────────────────────────────────────────────────────────
class _CustomerModel {
  final String id;
  final String name;
  final String initials;
  final String phone;
  final String altPhone;
  final String address;
  final String aadhaar;
  final String email;
  final String kycStatus;
  final int creditScore;
  final List<_HandsetModel> handsets;

  const _CustomerModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.phone,
    this.altPhone = '',
    required this.address,
    this.aadhaar = '',
    this.email = '',
    this.kycStatus = 'Verified',
    this.creditScore = 750,
    required this.handsets,
  });

  _CustomerModel copyWith({
    String? id,
    String? name,
    String? initials,
    String? phone,
    String? altPhone,
    String? address,
    String? aadhaar,
    String? email,
    String? kycStatus,
    int? creditScore,
    List<_HandsetModel>? handsets,
  }) {
    return _CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      address: address ?? this.address,
      aadhaar: aadhaar ?? this.aadhaar,
      email: email ?? this.email,
      kycStatus: kycStatus ?? this.kycStatus,
      creditScore: creditScore ?? this.creditScore,
      handsets: handsets ?? this.handsets,
    );
  }
}

class _HandsetModel {
  final String id;
  final String brand;
  final String model;
  final String storage;
  final String color;
  final int mrp;
  final String imei;
  final String serialNumber;
  final String warranty;

  const _HandsetModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.storage,
    required this.color,
    required this.mrp,
    required this.imei,
    required this.serialNumber,
    required this.warranty,
  });
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AddEmiPage extends StatefulWidget {
  const AddEmiPage({super.key});

  @override
  State<AddEmiPage> createState() => _AddEmiPageState();
}

class _AddEmiPageState extends State<AddEmiPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Section 1 – Customer & Handset
  _CustomerModel? _selectedCustomer;
  _HandsetModel? _selectedHandset;

  // Section 2 – Deal Financials & Tenure
  final _sellingPriceCtrl = TextEditingController();
  final _downPaymentCtrl = TextEditingController(text: '15000');
  String _paymentMode = 'UPI';

  // Tenure & Schedule
  int _selectedTenure = 12;
  final _manualDurationCtrl = TextEditingController(text: '12');
  DateTime _firstEmiDate = DateTime.now();

  // Submission & Success state
  bool _isSubmitting = false;
  bool _showSuccessScreen = false;
  int _redirectCountdown = 3;
  Timer? _countdownTimer;
  String _createdPlanId = '';

  // Helpers
  String _getOrdinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  // Computed values
  double get _mrp {
    final parsedSellingPrice = double.tryParse(
      _sellingPriceCtrl.text.replaceAll(',', '').trim(),
    );
    if (parsedSellingPrice != null && parsedSellingPrice > 0) {
      return parsedSellingPrice;
    }
    return _selectedHandset != null ? _selectedHandset!.mrp.toDouble() : 0.0;
  }

  double get _downPayment =>
      double.tryParse(_downPaymentCtrl.text.replaceAll(',', '')) ?? 0.0;

  double get _financedPrincipal {
    final diff = _mrp - _downPayment;
    return diff > 0 ? diff : 0.0;
  }

  double get _totalPayable => _financedPrincipal;

  double get _monthlyEmi => _selectedTenure > 0
      ? (_totalPayable / _selectedTenure).roundToDouble()
      : 0.0;

  int get _downPaymentPercent {
    if (_mrp == 0) return 0;
    return ((_downPayment / _mrp) * 100).round();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final day = now.day > 28 ? 28 : now.day;
    _firstEmiDate = DateTime(now.year, now.month + 1, day);
    _sellingPriceCtrl.addListener(_recalc);
    _downPaymentCtrl.addListener(_recalc);
  }

  void _recalc() => setState(() {});

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _sellingPriceCtrl.dispose();
    _downPaymentCtrl.dispose();
    _manualDurationCtrl.dispose();
    super.dispose();
  }

  void _onCustomerSelected(_CustomerModel c) {
    setState(() {
      _selectedCustomer = c;
      if (c.handsets.isNotEmpty) {
        _selectedHandset = c.handsets.first;
        _sellingPriceCtrl.text = _selectedHandset!.mrp.toString();
      } else {
        _selectedHandset = null;
        _sellingPriceCtrl.text = '';
      }
    });
  }

  void _onHandsetSelected(_HandsetModel h) {
    setState(() {
      _selectedHandset = h;
      _sellingPriceCtrl.text = h.mrp.toString();
    });
  }

  static const _quickTenures = [3, 6, 9, 12];

  void _setTenure(int months) {
    setState(() {
      _selectedTenure = months;
      _manualDurationCtrl.text = months.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccessScreen) {
      return _buildSuccessOverlay();
    }

    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Scaffold(
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const SizedBox(height: 12),
            _section1CustomerHandset(),
            const SizedBox(height: 12),
            _section2DealFinancials(fmt),
            const SizedBox(height: 12),
            _financialSummary(fmt),
          ],
        ),
      ),
      bottomNavigationBar: _reviewButton(),
    );
  }

  /// 3-Second Success Overlay
  Widget _buildSuccessOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA7F3D0),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF10B981),
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'EMI Agreement Created!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'EMI Plan ${_createdPlanId.isNotEmpty ? '#$_createdPlanId ' : ''}successfully created for ${_selectedCustomer?.name ?? 'customer'}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Redirecting to Dashboard in $_redirectCountdown s...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPurple,
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

  // ─── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: textColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    'New Mobile EMI Setup',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 – Customer & Handset Details
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _section1CustomerHandset() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _circleNumber(1),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Customer & Handset\nDetails',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _kBlueDark,
                  ),
                ),
              ),
              _outlineBtn(
                label: _selectedCustomer == null ? 'Select / Change' : 'Change',
                icon: Icons.person_search_rounded,
                onTap: _showCustomerSheet,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_selectedCustomer == null)
            _emptySelectBox(
              icon: Icons.person_rounded,
              label: 'Select a customer from API to begin',
              onTap: _showCustomerSheet,
            )
          else ...[
            _customerCard(_selectedCustomer!),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  size: 15,
                  color: isDark ? AppColors.textSecondaryDark : _kGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tagged Handset',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : _kBlueDark,
                  ),
                ),
                const Spacer(),
                _outlineBtn(
                  label: _selectedHandset == null ? 'Select' : 'Change',
                  icon: Icons.phone_android_rounded,
                  onTap: _showHandsetSheet,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedHandset == null)
              _emptySelectBox(
                icon: Icons.phone_android_rounded,
                label: _selectedCustomer!.handsets.isEmpty
                    ? 'No handset linked to ${_selectedCustomer!.name} (Add via Dashboard)'
                    : 'Select a handset linked to this customer',
                onTap: _showHandsetSheet,
              )
            else
              _handsetCard(_selectedHandset!),
          ],
        ],
      ),
    );
  }

  Widget _circleNumber(int n) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _kPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$n',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _emptySelectBox({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : _kPurpleLight,
          border: Border.all(
            color: isDark
                ? _kPurple.withValues(alpha: 0.5)
                : _kPurple.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDark ? const Color(0xFFA29BFE) : _kPurple,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFFA29BFE) : _kPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to select →',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFFA29BFE).withValues(alpha: 0.7)
                    : _kPurple.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(_CustomerModel c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : _kGreyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF9B8FF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    c.initials,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _kBlueDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.phone,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : _kGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (c.address.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: isDark ? AppColors.textSecondaryDark : _kGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    c.address,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : _kGrey,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _handsetCard(_HandsetModel h) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : _kGreyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : _kBlueDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h.brand} ${h.model}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _kBlueDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${h.storage}  •  ${h.color}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : _kGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${fmt.format(h.mrp)} MRP',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _kBlueDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _showHandsetSheet,
                    child: Text(
                      'Change',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark ? const Color(0xFFA78BFA) : _kPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoChip(
            label: 'DEVICE IMEI',
            value: h.imei.isNotEmpty ? h.imei : 'Not Recorded',
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required String label, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: isDark ? AppColors.textSecondaryDark : _kGrey,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white : _kBlueDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 – Deal Financials & Tenure (Merged)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _section2DealFinancials(NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _circleNumber(2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Deal Financials & Tenure',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _kBlueDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selling Price + Down Payment
          Row(
            children: [
              Expanded(
                child: _labeledAmountField(
                  label: 'Selling Price (MRP) *',
                  controller: _sellingPriceCtrl,
                  hint: '0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Down Payment',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : _kGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF064E3B)
                                : _kGreenLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_downPaymentPercent% paid',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: isDark ? const Color(0xFF34D399) : _kGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _rupeePrefixField(controller: _downPaymentCtrl, hint: '0'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Down Payment Mode
          Text(
            'Down Payment Mode',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : _kGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _paymentModeDropdown(),
          const SizedBox(height: 14),

          // Financed Principal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B4B) : _kPurpleLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF4338CA)
                    : _kPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: isDark ? const Color(0xFFA78BFA) : _kPurple,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Financed Principal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFA78BFA) : _kPurple,
                        ),
                      ),
                      // Text(
                      //   'Total loan balance to amortize (0% fee)',
                      //   style: GoogleFonts.inter(
                      //     fontSize: 10,
                      //     color: isDark
                      //         ? const Color(0xFFC4B5FD)
                      //         : _kPurple.withValues(alpha: 0.6),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                Text(
                  '₹${fmt.format(_financedPrincipal)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _kPurple,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Divider(height: 1, color: isDark ? AppColors.borderDark : _kBorder),
          const SizedBox(height: 18),

          // Tenure & Installments section (merged into this single box)
          Row(
            children: [
              Text(
                'EMI Tenure Selection',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _kBlueDark,
                ),
              ),
              const Spacer(),
              Text(
                '$_selectedTenure Months',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFA78BFA) : _kPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick tenure buttons
          Row(
            children: _quickTenures.map((t) {
              final sel = _selectedTenure == t;
              final isLast = t == _quickTenures.last;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _setTenure(t),
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: sel
                          ? _kPurple
                          : (isDark ? AppColors.surfaceDark : _kCardBg),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? _kPurple
                            : (isDark ? AppColors.borderDark : _kBorder),
                        width: sel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${t}M',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? Colors.white
                              : (isDark ? AppColors.textSecondaryDark : _kGrey),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Extended + Manual
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extended Tenure',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : _kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: 'More options...',
                      dropdownColor: isDark
                          ? AppColors.surfaceDark
                          : Colors.white,
                      onChanged: (val) {
                        if (val != null && val.contains('M')) {
                          final parsed = int.tryParse(val.replaceAll('M', ''));
                          if (parsed != null) _setTenure(parsed);
                        }
                      },
                      decoration: _inputDec(hint: ''),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white : _kBlueDark,
                      ),
                      items: ['More options...', '15M', '18M', '24M']
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v,
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : _kBlueDark,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Duration',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : _kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _manualDurationCtrl,
                            keyboardType: TextInputType.number,
                            cursorColor: isDark ? Colors.white : _kPurple,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) {
                              final p = int.tryParse(v);
                              if (p != null && p > 0) {
                                setState(() => _selectedTenure = p);
                              }
                            },
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : _kBlueDark,
                            ),
                            decoration: _inputDec(hint: '12'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mo',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : _kGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calculated EMI Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A3CBF), Color(0xFF6C5CE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  'CALCULATED MONTHLY EMI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${fmt.format(_monthlyEmi)} / month',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'for $_selectedTenure monthly installments  •  Total: ₹${fmt.format(_totalPayable)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // First EMI Due Date + Synced Billing Cycle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First EMI Due Date',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : _kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _firstEmiDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _firstEmiDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : _kCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : _kBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_firstEmiDate),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : _kBlueDark,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : _kGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Billing Cycle',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : _kGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF064E3B)
                                : _kGreenLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Synced',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF34D399) : _kGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : _kBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_getOrdinal(_firstEmiDate.day)} of every month',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : _kBlueDark,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF34D399) : _kGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeledAmountField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : _kGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _rupeePrefixField(controller: controller, hint: hint),
      ],
    );
  }

  Widget _rupeePrefixField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      cursorColor: isDark ? Colors.white : _kPurple,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : _kBlueDark,
      ),
      onChanged: (_) => setState(() {}),
      decoration: _inputDec(hint: hint, prefix: '₹'),
    );
  }

  InputDecoration _inputDec({
    String? prefix,
    String? suffix,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        color: isDark ? AppColors.textSecondaryDark : _kBorder,
      ),
      prefixText: prefix,
      prefixStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : _kGrey,
      ),
      suffixText: suffix,
      suffixStyle: GoogleFonts.inter(
        fontSize: 13,
        color: isDark ? Colors.white70 : _kGrey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : _kCardBg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : _kBorder,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPurple, width: 1.5),
      ),
    );
  }

  Widget _paymentModeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const modes = ['UPI', 'Cash', 'Card', 'Bank Transfer', 'Cheque'];
    return DropdownButtonFormField<String>(
      initialValue: _paymentMode,
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      onChanged: (v) => setState(() => _paymentMode = v!),
      decoration: _inputDec(hint: ''),
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : _kBlueDark,
      ),
      items: modes
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(
                m,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : _kBlueDark,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ─── Financial Summary ────────────────────────────────────────────────────
  Widget _financialSummary(NumberFormat fmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 16, color: _kPurple),
              const SizedBox(width: 6),
              Text(
                'Financial Summary',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _kBlueDark,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? AppColors.borderDark : _kBorder),
          const SizedBox(height: 10),
          _summaryRow(
            'Device Price (MRP)',
            '₹${fmt.format(_mrp)}',
            color: isDark ? Colors.white : _kBlueDark,
          ),
          _summaryRow(
            'Down Payment Collected',
            '-₹${fmt.format(_downPayment)}',
            color: _kRed,
          ),
          _summaryRow(
            'Net Financed Principal',
            '₹${fmt.format(_financedPrincipal)}',
            color: isDark ? Colors.white : _kBlueDark,
          ),
          _summaryRow(
            'Tenure & Schedule',
            '$_selectedTenure Mo • ${_getOrdinal(_firstEmiDate.day)} of month',
            color: isDark ? AppColors.textSecondaryDark : _kGrey,
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: isDark ? AppColors.borderDark : _kBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total EMI Repayment',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _kBlueDark,
                    ),
                  ),
                  Text(
                    '$_selectedTenure installments x ₹${fmt.format(_monthlyEmi)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDark ? AppColors.textSecondaryDark : _kGrey,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${fmt.format(_totalPayable)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFA78BFA) : _kPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : _kGrey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Review Button ────────────────────────────────────────────────────────
  Widget _reviewButton() {
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
          onPressed: _isSubmitting
              ? null
              : (_selectedCustomer != null && _selectedHandset != null
                    ? _onReview
                    : null),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPurple,
            disabledBackgroundColor: isDark
                ? const Color(0xFF334155)
                : _kBorder,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.article_rounded, size: 18),
          label: Text(
            _isSubmitting
                ? 'Creating EMI Agreement...'
                : 'Review & Create EMI Agreement  →',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ─── Review & API Integration ─────────────────────────────────────────────
  Future<void> _onReview() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer first.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedHandset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or configure a handset for this EMI.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sellingPrice = _mrp;
    if (sellingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selling price must be greater than ₹0.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_downPayment > sellingPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Down payment cannot exceed selling price.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedTenure <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid financing tenure.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final loanAmount = sellingPrice - _downPayment;
      final monthlyInstallment = _monthlyEmi > 0
          ? _monthlyEmi
          : (loanAmount / _selectedTenure).roundToDouble();

      final request = CreateCustomerRequestModel(
        saleType: 'EMI',
        fullName: _selectedCustomer!.name,
        mobileNumber: _selectedCustomer!.phone
            .replaceAll('+91', '')
            .replaceAll(' ', '')
            .trim(),
        email: _selectedCustomer!.email.isNotEmpty
            ? _selectedCustomer!.email
            : null,
        address: _selectedCustomer!.address.isNotEmpty
            ? _selectedCustomer!.address
            : null,
        aadhaarNumber: _selectedCustomer!.aadhaar.isNotEmpty
            ? _selectedCustomer!.aadhaar
            : null,
        brand: _selectedHandset!.brand,
        modelName: _selectedHandset!.model,
        imei: _selectedHandset!.imei.isNotEmpty ? _selectedHandset!.imei : null,
        storageVariant: _selectedHandset!.storage,
        color: _selectedHandset!.color,
        notes: _selectedHandset!.warranty,
        sellingPrice: sellingPrice,
        downPayment: _downPayment,
        loanAmount: loanAmount,
        tenureMonths: _selectedTenure,
        monthlyInstallment: monthlyInstallment,
        firstEmiDueDate: _firstEmiDate.toUtc().toIso8601String(),
        downPaymentMethod: _paymentMode == 'Cash'
            ? 'CASH'
            : (_paymentMode == 'UPI'
                  ? 'UPI'
                  : (_paymentMode == 'Card' ? 'CARD' : 'BANK_TRANSFER')),
        downPaymentReference: 'DP-${now.millisecondsSinceEpoch % 10000}',
      );

      final response = await sl<CustomerRepository>().createCustomer(request);

      // Trigger immediate background refresh of dashboard data
      sl<DashboardBloc>().add(const LoadDashboard());

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _createdPlanId = response.emiPlanId;
        _showSuccessScreen = true;
        _redirectCountdown = 3;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_redirectCountdown > 1) {
          setState(() => _redirectCountdown--);
        } else {
          timer.cancel();
          sl<DashboardBloc>().add(const LoadDashboard());
          context.go(RoutePaths.dashboard);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final failure = ErrorMapper.toFailure(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(failure.message)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Bottom Sheet: Customer ───────────────────────────────────────────────
  void _showCustomerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerSelectionSheet(onSelected: _onCustomerSelected),
    );
  }

  // ─── Bottom Sheet: Handset ────────────────────────────────────────────────
  void _showHandsetSheet() {
    if (_selectedCustomer == null) {
      _showCustomerSheet();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _HandsetSelectionSheet(
        handsets: _selectedCustomer!.handsets,
        customerName: _selectedCustomer!.name,
        onSelected: (h) {
          Navigator.of(sheetCtx).pop();
          _onHandsetSelected(h);
        },
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _outlineBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2459) : _kPurpleLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF8B5CF6)
                : _kPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isDark ? const Color(0xFFA78BFA) : _kPurple,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA78BFA) : _kPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Customer Selection Bottom Sheet (Pulls from API) ────────────────────────
class _CustomerSelectionSheet extends StatefulWidget {
  final ValueChanged<_CustomerModel> onSelected;

  const _CustomerSelectionSheet({required this.onSelected});

  @override
  State<_CustomerSelectionSheet> createState() =>
      _CustomerSelectionSheetState();
}

class _CustomerSelectionSheetState extends State<_CustomerSelectionSheet> {
  final _searchController = TextEditingController();
  List<CustomerListItemModel> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _loadingCustomerId;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCustomers({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await sl<CustomerRepository>().listCustomers(
        limit: 50,
        search: (search != null && search.trim().isNotEmpty)
            ? search.trim()
            : null,
      );
      if (!mounted) return;
      setState(() {
        _customers = res.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final failure = ErrorMapper.toFailure(e);
      setState(() {
        _errorMessage = failure.message;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchCustomers(search: query);
    });
  }

  Future<void> _handleCustomerTap(CustomerListItemModel item) async {
    setState(() => _loadingCustomerId = item.id);

    try {
      final details = await sl<CustomerRepository>().getCustomerDetails(
        item.id,
      );
      final rawHandsets = (details['handsets'] as List<dynamic>?) ?? [];
      final handsets = <_HandsetModel>[];

      for (final h in rawHandsets) {
        if (h is Map<String, dynamic>) {
          handsets.add(
            _HandsetModel(
              id: h['id']?.toString() ?? h['_id']?.toString() ?? '',
              brand: h['brand']?.toString() ?? 'Smartphone',
              model:
                  h['modelName']?.toString() ??
                  h['model']?.toString() ??
                  'Model',
              storage:
                  h['storageVariant']?.toString() ??
                  h['storage']?.toString() ??
                  '128GB',
              color: h['color']?.toString() ?? 'Black',
              mrp:
                  (h['sellingPrice'] as num?)?.toInt() ??
                  (h['mrp'] as num?)?.toInt() ??
                  50000,
              imei: h['imei']?.toString() ?? '',
              serialNumber: h['serialNumber']?.toString() ?? '',
              warranty: 'Brand New Sealed • 1 Year Warranty',
            ),
          );
        }
      }

      if (handsets.isEmpty &&
          item.deviceName != null &&
          item.deviceName!.isNotEmpty) {
        handsets.add(
          _HandsetModel(
            id: 'dev-${item.id}',
            brand: item.deviceName!.split(' ').first,
            model: item.deviceName!,
            storage: '128GB',
            color: 'Standard',
            mrp: (item.installmentAmount != null && item.totalEmiMonths != null)
                ? (item.installmentAmount! * item.totalEmiMonths!).round()
                : 50000,
            imei: item.imei ?? '',
            serialNumber: '',
            warranty: 'Registered Device',
          ),
        );
      }

      final initials = item.name.trim().isNotEmpty
          ? item.name
                .trim()
                .split(' ')
                .map((p) => p.isNotEmpty ? p[0] : '')
                .take(2)
                .join()
                .toUpperCase()
          : 'CU';

      final customerModel = _CustomerModel(
        id: item.id,
        name: item.name,
        initials: initials,
        phone: item.mobileNumber,
        address: item.address ?? '',
        email: item.email ?? '',
        aadhaar: (details['aadhaarNumber'] ?? '').toString(),
        kycStatus: (details['isActive'] == false) ? 'Pending' : 'Verified',
        creditScore: 750,
        handsets: handsets,
      );

      if (!mounted) return;
      widget.onSelected(customerModel);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCustomerId = null);
      final initials = item.name.trim().isNotEmpty
          ? item.name
                .trim()
                .split(' ')
                .map((p) => p.isNotEmpty ? p[0] : '')
                .take(2)
                .join()
                .toUpperCase()
          : 'CU';
      final customerModel = _CustomerModel(
        id: item.id,
        name: item.name,
        initials: initials,
        phone: item.mobileNumber,
        address: item.address ?? '',
        email: item.email ?? '',
        aadhaar: '',
        kycStatus: 'Verified',
        creditScore: 720,
        handsets: [],
      );
      widget.onSelected(customerModel);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : _kCardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : _kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select Customer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : _kBlueDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                cursorColor: isDark ? Colors.white : _kPurple,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white : _kBlueDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search customers by name or phone…',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: _kGrey),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: _kGrey,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _fetchCustomers();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : _kGreyLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(ctrl, isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController ctrl, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPurple));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchCustomers(search: _searchController.text),
              style: ElevatedButton.styleFrom(backgroundColor: _kPurple),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded, color: _kGrey, size: 40),
            const SizedBox(height: 10),
            Text(
              'No customers found',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with a different name or number',
              style: GoogleFonts.inter(fontSize: 12, color: _kGrey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: ctrl,
      itemCount: _customers.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: isDark ? AppColors.borderDark : _kBorder),
      itemBuilder: (_, i) {
        final c = _customers[i];
        final isSelectedLoading = _loadingCustomerId == c.id;
        final initials = c.name.trim().isNotEmpty
            ? c.name
                  .trim()
                  .split(' ')
                  .map((p) => p.isNotEmpty ? p[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase()
            : 'CU';

        return ListTile(
          onTap: isSelectedLoading ? null : () => _handleCustomerTap(c),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF9B8FF0)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          title: Text(
            c.name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : _kBlueDark,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.mobileNumber,
                style: GoogleFonts.inter(fontSize: 11, color: _kGrey),
              ),
              if (c.deviceName != null && c.deviceName!.isNotEmpty)
                Text(
                  'Device: ${c.deviceName}',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: _kPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          trailing: isSelectedLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kPurple,
                  ),
                )
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: _kGrey,
                  size: 20,
                ),
        );
      },
    );
  }
}

// ─── Handset Selection Bottom Sheet ──────────────────────────────────────────
class _HandsetSelectionSheet extends StatelessWidget {
  final List<_HandsetModel> handsets;
  final String customerName;
  final ValueChanged<_HandsetModel> onSelected;

  const _HandsetSelectionSheet({
    required this.handsets,
    required this.customerName,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (_, ctrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : _kCardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : _kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Handset',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : _kBlueDark,
                        ),
                      ),
                      Text(
                        'Devices linked to $customerName',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : _kGrey,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.textSecondaryDark : _kGrey,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: handsets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other_rounded,
                              size: 44,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : _kGrey,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No handsets linked to this customer yet',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : _kGrey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add a device from Dashboard (+ Add Device)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : _kGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: ctrl,
                        itemCount: handsets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final h = handsets[i];
                          return InkWell(
                            onTap: () => onSelected(h),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : _kGreyLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : _kBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : _kBlueDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.phone_android_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${h.brand} ${h.model}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : _kBlueDark,
                                          ),
                                        ),
                                        Text(
                                          '${h.storage}  •  ${h.color}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : _kGrey,
                                          ),
                                        ),
                                        if (h.imei.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'IMEI: ${h.imei}',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : _kGrey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${fmt.format(h.mrp)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : _kBlueDark,
                                        ),
                                      ),
                                      Text(
                                        'MRP',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : _kGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: _kPurple,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
