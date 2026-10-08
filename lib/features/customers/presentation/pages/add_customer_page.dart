import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_emi_manager/app/router/route_paths.dart';
import 'package:mobile_emi_manager/app/theme/app_colors.dart';
import 'package:mobile_emi_manager/app/theme/app_dimensions.dart';
import 'package:mobile_emi_manager/app/theme/app_text_styles.dart';
import 'package:mobile_emi_manager/core/di/injection_container.dart';
import 'package:mobile_emi_manager/core/errors/error_mapper.dart';
import 'package:mobile_emi_manager/features/customers/data/models/customer_models.dart';
import 'package:mobile_emi_manager/features/customers/domain/repositories/customer_repository.dart';
import 'package:mobile_emi_manager/features/dashboard/presentation/bloc/dashboard_bloc.dart';

/// Add Customer & Device page with API integration.
class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

enum SaleType { emi, cash }

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  // Field Keys for Auto-Scroll on Validation Failure
  final _fullNameKey = GlobalKey();
  final _mobileKey = GlobalKey();
  final _cityAreaKey = GlobalKey();
  final _modelNameKey = GlobalKey();
  final _priceKey = GlobalKey();

  // Focus Nodes for Auto-Focus
  final _fullNameFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _cityAreaFocus = FocusNode();
  final _modelNameFocus = FocusNode();
  final _priceFocus = FocusNode();

  // Customer Details
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityAreaController = TextEditingController();
  final _aadhaarController = TextEditingController();

  // Device Details
  String _selectedBrand = 'Samsung';
  final _modelNameController = TextEditingController();
  final _imeiController = TextEditingController();
  final _storageController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  // Payment & EMI Terms
  SaleType _selectedSaleType = SaleType.emi;
  final _priceController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _customTenureController = TextEditingController();

  int _selectedTenureMonths = 9;
  DateTime _firstEmiDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;
  bool _showSuccessScreen = false;
  int _redirectCountdown = 3;
  Timer? _countdownTimer;

  String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  final List<String> _brands = [
    'Samsung',
    'Apple',
    'OnePlus',
    'Xiaomi/Redmi',
    'Vivo',
    'Oppo',
    'Realme',
    'Motorola',
    'Others',
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fullNameFocus.dispose();
    _mobileFocus.dispose();
    _cityAreaFocus.dispose();
    _modelNameFocus.dispose();
    _priceFocus.dispose();
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityAreaController.dispose();
    _aadhaarController.dispose();
    _modelNameController.dispose();
    _imeiController.dispose();
    _storageController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _downPaymentController.dispose();
    _customTenureController.dispose();
    super.dispose();
  }

  double _parseAmount(String text) {
    final cleaned = text.replaceAll(',', '').replaceAll('₹', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  double get _sellingPrice => _parseAmount(_priceController.text);
  double get _downPayment {
    if (_selectedSaleType == SaleType.cash) {
      return _sellingPrice;
    }
    return _parseAmount(_downPaymentController.text);
  }

  double get _loanBalance {
    if (_selectedSaleType == SaleType.cash) return 0.0;
    final balance = _sellingPrice - _downPayment;
    return balance > 0 ? balance : 0.0;
  }

  double get _monthlyInstallment {
    if (_selectedSaleType == SaleType.cash ||
        _selectedTenureMonths <= 0 ||
        _loanBalance <= 0) {
      return 0.0;
    }
    return (_loanBalance / _selectedTenureMonths).roundToDouble();
  }

  Future<void> _selectCustomTenureYear() async {
    final now = DateTime.now();
    final currentYear = now.year;
    final maxYear = currentYear + 20;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pickedYear = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF6C5CE7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Tenure (Years)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current year ($currentYear) up to 20 years ($maxYear)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                const SizedBox(height: 14),

                // 20-Year Calendar Grid (currentYear + 1 to currentYear + 20)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: 20,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.35,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final year = currentYear + (index + 1);
                      final tenureYears = index + 1;
                      final tenureMonths = tenureYears * 12;
                      final isSelected = _customTenureController.text.isNotEmpty &&
                          _selectedTenureMonths == tenureMonths;

                      return InkWell(
                        onTap: () => Navigator.pop(ctx, year),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6C5CE7)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6C5CE7)
                                  : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$year',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$tenureYears ${tenureYears == 1 ? "Yr" : "Yrs"} (${tenureMonths}M)',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white70
                                      : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedYear != null) {
      final tenureYears = pickedYear - currentYear;
      final tenureMonths = tenureYears * 12;
      setState(() {
        _selectedTenureMonths = tenureMonths;
        _customTenureController.text =
            '$tenureYears ${tenureYears == 1 ? "Year" : "Years"} ($pickedYear)';
      });
    }
  }

  Future<void> _selectFirstEmiDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstEmiDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT FIRST EMI DUE DATE',
    );
    if (picked != null) {
      setState(() => _firstEmiDate = picked);
    }
  }

  void _scrollToContext(BuildContext? targetContext) {
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    }
  }

  Future<void> _saveCustomer() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      // Auto-scroll to first invalid mandatory field
      if (_fullNameController.text.trim().isEmpty) {
        _scrollToContext(_fullNameKey.currentContext);
        _fullNameFocus.requestFocus();
      } else if (_mobileController.text.trim().isEmpty) {
        _scrollToContext(_mobileKey.currentContext);
        _mobileFocus.requestFocus();
      } else if (_cityAreaController.text.trim().isEmpty) {
        _scrollToContext(_cityAreaKey.currentContext);
        _cityAreaFocus.requestFocus();
      } else if (_modelNameController.text.trim().isEmpty) {
        _scrollToContext(_modelNameKey.currentContext);
        _modelNameFocus.requestFocus();
      } else if (_priceController.text.trim().isEmpty) {
        _scrollToContext(_priceKey.currentContext);
        _priceFocus.requestFocus();
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      final request = CreateCustomerRequestModel(
        saleType: _selectedSaleType == SaleType.cash ? 'CASH' : 'EMI',
        fullName: _fullNameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        address: _cityAreaController.text.trim().isNotEmpty
            ? _cityAreaController.text.trim()
            : null,
        aadhaarNumber: _aadhaarController.text.trim().isNotEmpty
            ? _aadhaarController.text.trim()
            : null,
        brand: _selectedBrand,
        modelName: _modelNameController.text.trim(),
        imei: _imeiController.text.trim().isNotEmpty
            ? _imeiController.text.trim()
            : null,
        storageVariant: _storageController.text.trim().isNotEmpty
            ? _storageController.text.trim()
            : null,
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        sellingPrice: _sellingPrice,
        downPayment:
            _selectedSaleType == SaleType.cash ? _sellingPrice : _downPayment,
        loanAmount: _loanBalance,
        tenureMonths:
            _selectedSaleType == SaleType.cash ? 0 : _selectedTenureMonths,
        monthlyInstallment:
            _selectedSaleType == SaleType.cash ? 0.0 : _monthlyInstallment,
        firstEmiDueDate: _selectedSaleType == SaleType.cash
            ? null
            : _firstEmiDate.toIso8601String(),
        downPaymentMethod: 'CASH',
        downPaymentReference: 'CASH-REC-${now.millisecondsSinceEpoch % 10000}',
      );

      // Call API
      await sl<CustomerRepository>().createCustomer(request);

      // Trigger immediate background refresh of dashboard data
      sl<DashboardBloc>().add(const LoadDashboard());

      if (!mounted) return;

      setState(() {
        _isSaving = false;
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
      setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    if (_showSuccessScreen) {
      return _buildSuccessOverlay();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,##,###', 'en_IN');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color:
                  isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Customer & Device',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomStickyBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spaceSm),

              // ─── Section 1: Customer Details ──────────────────────────────
              _buildCustomerDetailsSection(),
              const SizedBox(height: AppDimensions.spaceMd),

              // ─── Section 2: Handset & Device Details ──────────────────────
              _buildDeviceDetailsSection(),
              const SizedBox(height: AppDimensions.spaceMd),

              // ─── Section 3: Payment & EMI Terms ───────────────────────────
              _buildPaymentAndEmiSection(currencyFormatter),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// 3-Second Success Screen Overlay
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
                // Animated Checkmark Container
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFA7F3D0), width: 3),
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
                  'Customer Saved Successfully!',
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
                  _selectedSaleType == SaleType.cash
                      ? 'Cash Sale record created successfully.'
                      : 'Customer details & EMI plan created successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 36),

                // Timer Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Redirecting to Dashboard in $_redirectCountdown s...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6C5CE7),
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

  /// Section 1: Customer Details
  Widget _buildCustomerDetailsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildSectionCard(
      title: 'Customer Details',
      pillTag: 'ESSENTIAL',
      pillColor: const Color(0xFFEDE9FE),
      pillTextColor: const Color(0xFF6C5CE7),
      children: [
        // Customer Full Name
        _buildFieldLabel('Customer Full Name *'),
        const SizedBox(height: 6),
        TextFormField(
          key: _fullNameKey,
          focusNode: _fullNameFocus,
          controller: _fullNameController,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. Rahul Sharma',
            prefixIcon: Icons.person_outline_rounded,
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Customer full name is required'
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // Primary Mobile Number Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('Primary Mobile Number *'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 13,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'WhatsApp Enabled',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Mobile Field with +91 prefix
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                ),
              ),
              child: Text(
                '+91',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: _mobileKey,
                focusNode: _mobileFocus,
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                cursorColor: isDark ? Colors.white : AppColors.primary,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                decoration: _inputDecoration(
                  hint: 'Enter 10-digit number',
                  suffixIcon: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Mobile number is required'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // City / Area
        _buildFieldLabel('City / Area *'),
        const SizedBox(height: 6),
        TextFormField(
          key: _cityAreaKey,
          focusNode: _cityAreaFocus,
          controller: _cityAreaController,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. MG Road, Pune',
            prefixIcon: Icons.location_on_outlined,
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'City / Area is required'
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // Email Address & Aadhaar (Optional)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Email (Optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: isDark ? Colors.white : AppColors.primary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      hint: 'e.g. name@gmail.com',
                      prefixIcon: Icons.email_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Aadhaar (Optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _aadhaarController,
                    keyboardType: TextInputType.number,
                    cursorColor: isDark ? Colors.white : AppColors.primary,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      hint: '12-digit Aadhaar',
                      prefixIcon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Section 2: Handset & Device Details
  Widget _buildDeviceDetailsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildSectionCard(
      title: 'Handset & Device Details',
      pillTag: 'COUNTER STOCK',
      pillColor: const Color(0xFFF1F5F9),
      pillTextColor: const Color(0xFF475569),
      children: [
        // Select Brand Dropdown
        _buildFieldLabel('Select Brand *'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedBrand,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B)),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          decoration: _inputDecoration(
            prefixIcon: Icons.branding_watermark_outlined,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: _brands.map((b) {
            return DropdownMenuItem(
              value: b,
              child: Text(
                b,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedBrand = val);
          },
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // Model Name
        _buildFieldLabel('Model Name *'),
        const SizedBox(height: 6),
        TextFormField(
          key: _modelNameKey,
          focusNode: _modelNameFocus,
          controller: _modelNameController,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. Samsung Galaxy S24 5G',
            prefixIcon: Icons.smartphone_outlined,
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Model name is required'
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // IMEI Number (15 Digits) (Optional)
        _buildFieldLabel('IMEI Number (15 Digits) (Optional)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _imeiController,
          keyboardType: TextInputType.number,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          decoration: _inputDecoration(
            hint: 'Enter 15-digit IMEI (Optional)',
            suffixIcon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF6C5CE7),
              size: 22,
            ),
          ),
          validator: (val) {
            if (val != null &&
                val.trim().isNotEmpty &&
                val.trim().length < 15) {
              return 'IMEI must be 15 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // Storage Variant & Device Color (2 Separate Fields)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Storage Variant'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _storageController,
                    cursorColor: isDark ? Colors.white : AppColors.primary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      hint: 'e.g. 128GB / 256GB',
                      prefixIcon: Icons.sd_storage_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Device Color'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _colorController,
                    cursorColor: isDark ? Colors.white : AppColors.primary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      hint: 'e.g. Onyx Black',
                      prefixIcon: Icons.palette_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // Additional Details / Notes (Optional)
        _buildFieldLabel('Additional Details / Notes (Optional)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. Serial no, Bill number, bundled screen guardian',
            prefixIcon: Icons.description_outlined,
          ),
        ),
      ],
    );
  }

  /// Sale Type Selector (EMI Financing vs Cash Sale)
  Widget _buildSaleTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Sale Type *'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedSaleType = SaleType.emi),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedSaleType == SaleType.emi
                        ? (isDark ? AppColors.primary : const Color(0xFF1E293B))
                        : (isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF1F5F9)),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: _selectedSaleType == SaleType.emi
                          ? (isDark ? AppColors.primary : const Color(0xFF1E293B))
                          : (isDark
                              ? AppColors.borderDark
                              : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_score_rounded,
                        size: 18,
                        color: _selectedSaleType == SaleType.emi
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'EMI Financing',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _selectedSaleType == SaleType.emi
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedSaleType = SaleType.cash),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedSaleType == SaleType.cash
                        ? const Color(0xFF059669)
                        : (isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF1F5F9)),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: _selectedSaleType == SaleType.cash
                          ? const Color(0xFF059669)
                          : (isDark
                              ? AppColors.borderDark
                              : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 18,
                        color: _selectedSaleType == SaleType.cash
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cash Sale (Full)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _selectedSaleType == SaleType.cash
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Section 3: Payment & EMI Terms
  Widget _buildPaymentAndEmiSection(NumberFormat currencyFormatter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCash = _selectedSaleType == SaleType.cash;

    return _buildSectionCard(
      title: 'Payment & EMI Terms',
      pillTag: isCash ? 'Full Cash Payment' : 'Auto Calculator',
      pillColor: isCash ? const Color(0xFFECFDF5) : const Color(0xFFEDE9FE),
      pillTextColor:
          isCash ? const Color(0xFF047857) : const Color(0xFF6C5CE7),
      children: [
        // Sale Type Selector
        _buildSaleTypeSelector(),
        const SizedBox(height: AppDimensions.spaceMd),

        // Device Selling Price
        _buildFieldLabel('Device Selling Price (₹) *'),
        const SizedBox(height: 6),
        TextFormField(
          key: _priceKey,
          focusNode: _priceFocus,
          controller: _priceController,
          keyboardType: TextInputType.number,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration(
            hint: 'e.g. 45,000',
            prefixIcon: Icons.payments_outlined,
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Selling price is required'
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        if (!isCash) ...[
          // Down Payment & Loan Balance Row
          Row(
            children: [
              // Down Payment Input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Down Payment'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _downPaymentController,
                      keyboardType: TextInputType.number,
                      cursorColor: isDark ? Colors.white : AppColors.primary,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        hint: 'e.g. 10,000',
                        prefixIcon: Icons.currency_rupee_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Loan / Balance (Auto Calculated)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Loan / Balance'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹ ${currencyFormatter.format(_loanBalance)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // Financing Tenure Header with Monthly Rate Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Financing Tenure'),
              Text(
                '= ₹${currencyFormatter.format(_monthlyInstallment)} / mo',
                style: const TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tenure Month Selector Chips (3, 6, 9, 12 Months)
          Row(
            children: [3, 6, 9, 12].map((months) {
              final isSelected = _selectedTenureMonths == months &&
                  _customTenureController.text.isEmpty;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTenureMonths = months;
                        _customTenureController.clear();
                      });
                    },
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C5CE7)
                            : (isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF1F5F9)),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6C5CE7)
                              : (isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6C5CE7)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$months Mo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Custom Tenure Input Row (with Year Calendar Picker Trigger)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectCustomTenureYear,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: IgnorePointer(
                    child: TextFormField(
                      controller: _customTenureController,
                      readOnly: true,
                      cursorColor: isDark ? Colors.white : AppColors.primary,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Custom Tenure (Select Year)',
                        prefixIcon: Icons.calendar_today_outlined,
                        suffixIcon: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF6C5CE7),
                          size: 22,
                        ),
                        borderColor: _customTenureController.text.isNotEmpty
                            ? const Color(0xFF6C5CE7)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _selectCustomTenureYear,
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: const Text(
                  'Years',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _customTenureController.text.isNotEmpty
                      ? const Color(0xFF6C5CE7)
                      : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                  foregroundColor: _customTenureController.text.isNotEmpty
                      ? Colors.white
                      : (isDark
                          ? Colors.white
                          : const Color(0xFF334155)),
                  elevation: _customTenureController.text.isNotEmpty ? 2 : 0,
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    side: BorderSide(
                      color: _customTenureController.text.isNotEmpty
                          ? const Color(0xFF6C5CE7)
                          : (isDark
                              ? AppColors.borderDark
                              : const Color(0xFFCBD5E1)),
                      width: _customTenureController.text.isNotEmpty ? 1.5 : 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),

          // Monthly Installment Highlight Box
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Monthly Installment:',
                      style: TextStyle(
                        color: Color(0xFF4C1D95),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${currencyFormatter.format(_monthlyInstallment)}',
                  style: const TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),

          // First EMI Due Date & Synced Billing Cycle
          _buildFirstEmiAndBillingCycle(),
        ] else ...[
          // Cash Sale Highlight Box
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Full Cash Payment:',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${currencyFormatter.format(_sellingPrice)}',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// First EMI Due Date & Billing Cycle
  Widget _buildFirstEmiAndBillingCycle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // First EMI Due Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('First EMI Due Date'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectFirstEmiDate,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_firstEmiDate),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xFF6C5CE7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Billing Cycle (Synced)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildFieldLabel('Billing Cycle'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE6FAF6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Synced',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF00B894),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_getOrdinal(_firstEmiDate.day)} of month',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.sync_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF00B894),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section Outer Card Container Builder
  Widget _buildSectionCard({
    required String title,
    required String pillTag,
    required Color pillColor,
    required Color pillTextColor,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? pillTextColor.withValues(alpha: 0.2)
                      : pillColor,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  pillTag,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : pillTextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color? borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
        fontSize: 13,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF64748B),
              size: 20)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(
          color: borderColor ??
              (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
          width: borderColor != null ? 1.5 : 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(
          color: borderColor ??
              (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
          width: borderColor != null ? 1.5 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(
          color: borderColor ?? const Color(0xFF6C5CE7),
          width: 1.5,
        ),
      ),
    );
  }

  /// Sticky Bottom Action Bar
  Widget _buildBottomStickyBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save Customer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}
