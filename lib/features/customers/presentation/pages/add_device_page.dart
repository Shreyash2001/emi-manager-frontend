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

enum DeviceSaleType { emi, cash }

class _ExistingCustomerData {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final String aadhaar;
  final int existingHandsetCount;

  const _ExistingCustomerData({
    required this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.email = '',
    this.aadhaar = '',
    this.existingHandsetCount = 0,
  });

  String get initials {
    if (name.trim().isEmpty) return 'CU';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, 1).toUpperCase();
  }
}

/// Screen to add a new device / handset to an existing customer
/// with options for both EMI Financing and Cash Sale.
class AddDevicePage extends StatefulWidget {
  final String? initialCustomerId;

  const AddDevicePage({super.key, this.initialCustomerId});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();

  // Selected Existing Customer
  _ExistingCustomerData? _selectedCustomer;
  bool _isLoadingCustomer = false;

  // Device Details
  String _selectedBrand = 'Samsung';
  final _modelNameController = TextEditingController();
  final _imeiController = TextEditingController();
  final _storageController = TextEditingController(text: '128GB');
  final _colorController = TextEditingController(text: 'Black');
  final _notesController = TextEditingController();

  // Payment & Sale Terms
  DeviceSaleType _selectedSaleType = DeviceSaleType.emi;
  final _priceController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _customTenureController = TextEditingController();

  int _selectedTenureMonths = 9;
  DateTime _firstEmiDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;
  bool _showSuccessScreen = false;
  int _redirectCountdown = 3;
  Timer? _countdownTimer;

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
  void initState() {
    super.initState();
    if (widget.initialCustomerId != null &&
        widget.initialCustomerId!.isNotEmpty) {
      _loadCustomerById(widget.initialCustomerId!);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

  Future<void> _loadCustomerById(String id) async {
    setState(() => _isLoadingCustomer = true);
    try {
      final details = await sl<CustomerRepository>().getCustomerDetails(id);
      final rawHandsets = (details['handsets'] as List<dynamic>?) ?? [];
      setState(() {
        _selectedCustomer = _ExistingCustomerData(
          id: details['id']?.toString() ?? details['_id']?.toString() ?? id,
          name: details['fullName']?.toString() ?? details['name']?.toString() ?? 'Customer',
          phone: details['mobileNumber']?.toString() ?? details['phone']?.toString() ?? '',
          address: details['address']?.toString() ?? '',
          email: details['email']?.toString() ?? '',
          aadhaar: details['aadhaarNumber']?.toString() ?? '',
          existingHandsetCount: rawHandsets.length,
        );
        _isLoadingCustomer = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCustomer = false);
    }
  }

  double _parseAmount(String val) {
    final clean = val.replaceAll(',', '').replaceAll('₹', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  double get _sellingPrice => _parseAmount(_priceController.text);

  double get _downPayment {
    if (_selectedSaleType == DeviceSaleType.cash) return _sellingPrice;
    return _parseAmount(_downPaymentController.text);
  }

  int get _downPaymentPercent {
    if (_sellingPrice <= 0) return 0;
    return ((_downPayment / _sellingPrice) * 100).clamp(0, 100).round();
  }

  double get _loanBalance {
    if (_selectedSaleType == DeviceSaleType.cash) return 0.0;
    final balance = _sellingPrice - _downPayment;
    return balance > 0 ? balance : 0.0;
  }

  double get _monthlyInstallment {
    if (_selectedSaleType == DeviceSaleType.cash ||
        _selectedTenureMonths <= 0 ||
        _loanBalance <= 0) {
      return 0.0;
    }
    return (_loanBalance / _selectedTenureMonths).roundToDouble();
  }

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

  // ─── Custom Tenure: Year-Only Calendar Picker ──────────────────────────────
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
                            'From current year ($currentYear) up to 20 years ($maxYear)',
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

  // ─── Customer Selection Modal ──────────────────────────────────────────────
  void _openCustomerSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ExistingCustomerSelectSheet(
        onSelected: (customer) {
          setState(() => _selectedCustomer = customer);
        },
      ),
    );
  }

  // ─── Save Device to Customer ────────────────────────────────────────────────
  Future<void> _saveDevice() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an existing customer first.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_sellingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid selling price.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final cleanMobile = _selectedCustomer!.phone
          .replaceAll('+91', '')
          .replaceAll(' ', '')
          .trim();

      final request = CreateCustomerRequestModel(
        saleType: _selectedSaleType == DeviceSaleType.cash ? 'CASH' : 'EMI',
        fullName: _selectedCustomer!.name,
        mobileNumber: cleanMobile,
        email: _selectedCustomer!.email.isNotEmpty ? _selectedCustomer!.email : null,
        address: _selectedCustomer!.address.isNotEmpty ? _selectedCustomer!.address : null,
        aadhaarNumber: _selectedCustomer!.aadhaar.isNotEmpty ? _selectedCustomer!.aadhaar : null,
        brand: _selectedBrand,
        modelName: _modelNameController.text.trim(),
        imei: _imeiController.text.trim().isNotEmpty ? _imeiController.text.trim() : null,
        storageVariant: _storageController.text.trim().isNotEmpty ? _storageController.text.trim() : null,
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        sellingPrice: _sellingPrice,
        downPayment: _selectedSaleType == DeviceSaleType.cash ? _sellingPrice : _downPayment,
        loanAmount: _selectedSaleType == DeviceSaleType.cash ? 0.0 : _loanBalance,
        tenureMonths: _selectedSaleType == DeviceSaleType.cash ? 0 : _selectedTenureMonths,
        monthlyInstallment: _selectedSaleType == DeviceSaleType.cash ? 0.0 : _monthlyInstallment,
        firstEmiDueDate: _selectedSaleType == DeviceSaleType.cash ? null : _firstEmiDate.toIso8601String(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        downPaymentMethod: 'CASH',
        downPaymentReference: 'DEV-REC-${DateTime.now().millisecondsSinceEpoch % 10000}',
      );

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
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Device to Existing Customer',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spaceSm),

              // ─── Section 1: Customer Selection ─────────────────────────────
              _buildCustomerSection(isDark),
              const SizedBox(height: AppDimensions.spaceMd),

              // ─── Section 2: Handset & Device Details ───────────────────────
              _buildDeviceDetailsSection(isDark),
              const SizedBox(height: AppDimensions.spaceMd),

              // ─── Section 3: Sale Type & Payment Terms (EMI / Cash) ────────
              _buildPaymentAndTermsSection(isDark, currencyFormatter),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section 1: Customer Card / Selector ───────────────────────────────────
  Widget _buildCustomerSection(bool isDark) {
    return _buildSectionCard(
      title: 'Target Customer',
      pillTag: _selectedCustomer != null ? 'ACCOUNT LINKED' : 'REQUIRED',
      pillColor: _selectedCustomer != null ? const Color(0xFFE6FAF6) : const Color(0xFFFEF3C7),
      pillTextColor: _selectedCustomer != null ? const Color(0xFF00B894) : const Color(0xFFD97706),
      children: [
        if (_isLoadingCustomer)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
          )
        else if (_selectedCustomer == null)
          InkWell(
            onTap: _openCustomerSearchSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F3FF),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_search_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select Existing Customer',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF4C1D95),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to search from customer database →',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
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
                          _selectedCustomer!.initials,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCustomer!.name,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedCustomer!.phone,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openCustomerSearchSheet,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF6C5CE7)),
                      label: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedCustomer!.address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _selectedCustomer!.address,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_selectedCustomer!.existingHandsetCount} device(s) currently registered',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C5CE7),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Section 2: Handset & Device Details ───────────────────────────────────
  Widget _buildDeviceDetailsSection(bool isDark) {
    return _buildSectionCard(
      title: 'Handset & Device Details',
      pillTag: 'NEW DEVICE',
      pillColor: const Color(0xFFF1F5F9),
      pillTextColor: const Color(0xFF475569),
      children: [
        _buildFieldLabel('Select Brand *'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedBrand,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
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

        _buildFieldLabel('Model Name *'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _modelNameController,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. Samsung Galaxy S24 5G / iPhone 15',
            prefixIcon: Icons.smartphone_outlined,
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Model name is required'
              : null,
        ),
        const SizedBox(height: AppDimensions.spaceMd),

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
            if (val != null && val.trim().isNotEmpty && val.trim().length < 15) {
              return 'IMEI must be 15 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spaceMd),

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
                      hint: 'e.g. 128GB',
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
                      hint: 'e.g. Phantom Black',
                      prefixIcon: Icons.color_lens_outlined,
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

  // ─── Section 3: Sale Type & Payment Terms (EMI / Cash) ─────────────────────
  Widget _buildPaymentAndTermsSection(bool isDark, NumberFormat currencyFormatter) {
    final isCash = _selectedSaleType == DeviceSaleType.cash;

    return _buildSectionCard(
      title: 'Payment & Sale Terms',
      pillTag: isCash ? 'FULL CASH' : 'EMI FINANCING',
      pillColor: isCash ? const Color(0xFFECFDF5) : const Color(0xFFEDE9FE),
      pillTextColor: isCash ? const Color(0xFF047857) : const Color(0xFF6C5CE7),
      children: [
        // Sale Type Selector
        Row(
          children: [
            // EMI Option
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedSaleType = DeviceSaleType.emi),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: !isCash
                        ? const Color(0xFF6C5CE7)
                        : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: !isCash
                          ? const Color(0xFF6C5CE7)
                          : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_score_rounded,
                        size: 18,
                        color: !isCash
                            ? Colors.white
                            : (isDark ? AppColors.textSecondaryDark : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'EMI Financing',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: !isCash
                              ? Colors.white
                              : (isDark ? AppColors.textSecondaryDark : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Cash Sale Option
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedSaleType = DeviceSaleType.cash),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isCash
                        ? const Color(0xFF059669)
                        : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isCash
                          ? const Color(0xFF059669)
                          : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 18,
                        color: isCash
                            ? Colors.white
                            : (isDark ? AppColors.textSecondaryDark : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cash Sale (Full)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCash
                              ? Colors.white
                              : (isDark ? AppColors.textSecondaryDark : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),

        // Device Price
        _buildFieldLabel('Device Selling Price (₹) *'),
        const SizedBox(height: 6),
        TextFormField(
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
            hint: 'e.g. 50,000',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFieldLabel('Down Payment'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE6FAF6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_downPaymentPercent% paid',
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

              // Loan Balance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Loan / Balance'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹ ${currencyFormatter.format(_loanBalance)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF334155),
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

          // Financing Tenure
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

          // Quick Chips (3, 6, 9, 12 Months)
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
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C5CE7)
                            : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6C5CE7)
                              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
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
                                : (isDark ? AppColors.textSecondaryDark : const Color(0xFF475569)),
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
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  foregroundColor: _customTenureController.text.isNotEmpty
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF334155)),
                  elevation: _customTenureController.text.isNotEmpty ? 2 : 0,
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    side: BorderSide(
                      color: _customTenureController.text.isNotEmpty
                          ? const Color(0xFF6C5CE7)
                          : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
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
          Row(
            children: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildFieldLabel('Billing Cycle'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          ),
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
        const SizedBox(height: AppDimensions.spaceMd),

        _buildFieldLabel('Sale Notes (Optional)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          cursorColor: isDark ? Colors.white : AppColors.primary,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. Added secondary device / promotional sale',
            prefixIcon: Icons.notes_outlined,
          ),
        ),
      ],
    );
  }

  // ─── Sticky Bottom Bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingHorizontal,
        AppDimensions.spaceSm,
        AppDimensions.pagePaddingHorizontal,
        MediaQuery.of(context).padding.bottom + AppDimensions.spaceSm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveDevice,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            elevation: 2,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_to_photos_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedSaleType == DeviceSaleType.cash
                          ? 'Save Cash Sale Device'
                          : 'Save Device & Setup EMI',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── 3-Second Success Screen ───────────────────────────────────────────────
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
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 50),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Device Added Successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_selectedBrand ${_modelNameController.text.trim()} added to ${_selectedCustomer?.name ?? 'customer'} with ${_selectedSaleType == DeviceSaleType.cash ? 'Cash Sale' : 'EMI agreement'}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
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

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
        fontSize: 12,
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
          ? Icon(
              prefixIcon,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              size: 20,
            )
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
          color: borderColor ?? (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
          width: borderColor != null ? 1.5 : 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(
          color: borderColor ?? (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
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
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? pillTextColor.withValues(alpha: 0.2) : pillColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
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
          const SizedBox(height: AppDimensions.spaceMd),
          ...children,
        ],
      ),
    );
  }
}

// ─── Bottom Sheet: Select Existing Customer ──────────────────────────────────
class _ExistingCustomerSelectSheet extends StatefulWidget {
  final ValueChanged<_ExistingCustomerData> onSelected;

  const _ExistingCustomerSelectSheet({required this.onSelected});

  @override
  State<_ExistingCustomerSelectSheet> createState() =>
      _ExistingCustomerSelectSheetState();
}

class _ExistingCustomerSelectSheetState
    extends State<_ExistingCustomerSelectSheet> {
  final _searchController = TextEditingController();
  List<CustomerListItemModel> _customers = [];
  bool _isLoading = true;
  String? _loadingCustomerId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await sl<CustomerRepository>().listCustomers(
        page: 1,
        limit: 50,
        search: (search != null && search.trim().isNotEmpty) ? search.trim() : null,
      );
      if (mounted) {
        setState(() {
          _customers = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorMapper.toFailure(e).message;
        });
      }
    }
  }

  Future<void> _handleCustomerTap(CustomerListItemModel c) async {
    setState(() => _loadingCustomerId = c.id);
    try {
      final details = await sl<CustomerRepository>().getCustomerDetails(c.id);
      final rawHandsets = (details['handsets'] as List<dynamic>?) ?? [];
      final fullData = _ExistingCustomerData(
        id: details['id']?.toString() ?? details['_id']?.toString() ?? c.id,
        name: details['fullName']?.toString() ?? details['name']?.toString() ?? c.name,
        phone: details['mobileNumber']?.toString() ?? details['phone']?.toString() ?? c.mobileNumber,
        address: details['address']?.toString() ?? '',
        email: details['email']?.toString() ?? '',
        aadhaar: details['aadhaarNumber']?.toString() ?? '',
        existingHandsetCount: rawHandsets.length,
      );
      if (mounted) {
        widget.onSelected(fullData);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        widget.onSelected(_ExistingCustomerData(
          id: c.id,
          name: c.name,
          phone: c.mobileNumber,
          existingHandsetCount: c.deviceName != null ? 1 : 0,
        ));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, ctrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select Customer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Search existing customer to attach the device',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (val) => _fetchCustomers(search: val),
                cursorColor: const Color(0xFF6C5CE7),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Search by customer name or phone...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C5CE7), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetchCustomers();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444))),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _fetchCustomers(search: _searchController.text),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : _customers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_off_rounded, color: Color(0xFF94A3B8), size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No customers found',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: ctrl,
                                itemCount: _customers.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (_, i) {
                                  final c = _customers[i];
                                  final isItemLoading = _loadingCustomerId == c.id;
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
                                    onTap: isItemLoading ? null : () => _handleCustomerTap(c),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF6C5CE7), Color(0xFF9B8FF0)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      c.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    subtitle: Text(
                                      c.mobileNumber,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                      ),
                                    ),
                                    trailing: isItemLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF6C5CE7),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Color(0xFF94A3B8),
                                            size: 20,
                                          ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
